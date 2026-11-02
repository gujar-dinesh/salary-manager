# Load test with correctness checks. Runs against a live server and exits non-zero if any invariant breaks.
#
#   WRITE_RATE_LIMIT=100000 bin/rails server        # in another terminal
#   ruby script/load_test.rb [base_url] [threads]
#
# Use a disposable database: the script creates employees and raises one employee's salary many times.

require "net/http"
require "json"

BASE = URI(ARGV[0] || "http://localhost:3000")
THREADS = (ARGV[1] || 40).to_i
# Scenario 3 shares 5 emails and 3 job titles between clients, so it needs at least 10 of them.
MIN_THREADS = 10
abort "Use at least #{MIN_THREADS} parallel clients (got #{THREADS})." if THREADS < MIN_THREADS
FAILURES = []

def request(method, path, body = nil)
  http = Net::HTTP.new(BASE.host, BASE.port)
  http.read_timeout = 30
  klass = { get: Net::HTTP::Get, post: Net::HTTP::Post, patch: Net::HTTP::Patch, delete: Net::HTTP::Delete }.fetch(method)
  req = klass.new(path, "Content-Type" => "application/json")
  req.body = body.to_json if body
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  res = http.request(req)
  elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
  [ res.code.to_i, (JSON.parse(res.body) rescue nil), elapsed ]
end

def in_parallel(count)
  results = Queue.new
  count.times.map { |i| Thread.new { results << yield(i) } }.each(&:join)
  Array.new(results.size) { results.pop }
end

def check(description, ok)
  puts "  #{ok ? 'PASS' : 'FAIL'} #{description}"
  FAILURES << description unless ok
end

def percentile(values, pct)
  sorted = values.sort
  sorted[[ (sorted.size * pct).ceil - 1, 0 ].max].round
end

puts "Target #{BASE}, #{THREADS} parallel clients"

puts "\n1. Mixed reads"
paths = [ "/api/employees?page=%d", "/api/employees?sort=salary&direction=desc&page=%d", "/api/employees?country=India&sort=hire_date&page=%d",
          "/api/employees?q=sha&page=%d", "/api/insights/countries", "/api/insights/overview", "/api/insights/job_titles?country=Germany" ]
reads = in_parallel(THREADS) { 25.times.map { request(:get, format(paths.sample, rand(1..50))) } }.flatten(1)
statuses = reads.map(&:first).tally
times = reads.map(&:last)
puts "  #{reads.size} requests, statuses #{statuses}, p50 #{percentile(times, 0.5)}ms p95 #{percentile(times, 0.95)}ms p99 #{percentile(times, 0.99)}ms"
check "every read succeeded", statuses.keys == [ 200 ]

puts "\n2. Many users raising the same salary at once"
_, page, = request(:get, "/api/employees?per_page=1")
id = page["employees"].first["id"]
_, before, = request(:get, "/api/employees/#{id}")
raise_by = 100
outcomes = in_parallel(THREADS) do
  attempts = 0
  loop do
    attempts += 1
    _, current, = request(:get, "/api/employees/#{id}")
    status, = request(:patch, "/api/employees/#{id}",
                      employee: { salary: current["salary"] + raise_by, lock_version: current["lock_version"] })
    break [ status, attempts ] unless status == 409
  end
end
_, after, = request(:get, "/api/employees/#{id}")
successes = outcomes.count { |status, _| status == 200 }
new_changes = after["salary_changes"].size - before["salary_changes"].size
chain = after["salary_changes"].reverse.each_cons(2).all? { |older, newer| older["new_salary"] == newer["old_salary"] }
puts "  #{successes} raises saved after #{outcomes.sum(&:last) - successes} conflict retries"
check "every raise was saved", successes == THREADS
check "final salary includes every raise (#{before['salary']} -> #{after['salary']})",
      after["salary"] == before["salary"] + raise_by * THREADS
check "one history row per raise", new_changes == THREADS
check "history forms an unbroken chain", chain

puts "\n3. Parallel creates sharing new job titles and some emails"
run = rand(1_000_000)
titles = 3.times.map { |i| "Load Title #{run}-#{i}" }
emails = 5.times.map { |i| "load.#{run}.#{i}@acme.test" }
created = in_parallel(THREADS) do |i|
  status, body, = request(:post, "/api/employees", employee: {
    full_name: "Load User #{i}", email: emails[i % emails.size].sub("@", (i < emails.size * 2 ? "" : "+#{i}") + "@"),
    job_title: titles[i % titles.size].upcase.then { |t| i.even? ? t : t.downcase }, department: "Engineering",
    country: "India", salary: 1_000_000, employment_type: "full_time", hire_date: "2024-01-01"
  })
  [ status, body ]
end
statuses = created.map(&:first).tally
puts "  statuses #{statuses}"
check "only 201 or 422 responses (no 500s)", (statuses.keys - [ 201, 422 ]).empty?
_, options, = request(:get, "/api/employees/options")
titles.each do |title|
  matches = options["job_titles"].count { |t| t.casecmp?(title) }
  check "exactly one '#{title}' job title", matches == 1
end
duplicate_errors = created.count { |status, body| status == 422 && body.dig("errors", "email")&.include?("has already been taken") }
check "each shared email saved once, the rest rejected as duplicates", duplicate_errors == emails.size

created.select { |status, _| status == 201 }.each { |_, body| request(:delete, "/api/employees/#{body['id']}") }

puts
if FAILURES.empty?
  puts "All invariants held."
else
  puts "#{FAILURES.size} invariant(s) failed."
  exit 1
end

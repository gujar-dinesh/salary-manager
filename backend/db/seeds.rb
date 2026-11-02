result = EmployeeSeeder.seed(force: ENV["RESET_DEMO_DATA"] == "1")

if result == :skipped
  puts "Employees already exist, not replacing them in production. Set RESET_DEMO_DATA=1 to force."
else
  puts "Seeded #{Employee.count} employees"
end

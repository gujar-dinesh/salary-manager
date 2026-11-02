FactoryBot.define do
  factory :employee do
    sequence(:full_name) { |n| "Employee #{n}" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    job_title { "Software Engineer" }
    department { "Engineering" }
    country { "India" }
    salary { 1_200_000 }
    employment_type { "full_time" }
    hire_date { Date.new(2022, 4, 1) }
  end
end

FactoryBot.define do
  factory :employee do
    transient do
      country { "India" }
      department { "Engineering" }
      job_title { "Software Engineer" }
    end

    sequence(:full_name) { |n| "Employee #{n}" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    salary { 1_200_000 }
    employment_type { "full_time" }
    hire_date { Date.new(2022, 4, 1) }

    after(:build) do |employee, context|
      employee.country = Country.find_by(name: context.country)
      employee.department = Department.named(context.department)
      employee.job_title = JobTitle.named(context.job_title)
    end
  end
end

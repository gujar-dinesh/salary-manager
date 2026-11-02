FactoryBot.define do
  factory :employee do
    transient do
      country { "India" }
    end

    sequence(:full_name) { |n| "Employee #{n}" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    job_title { "Software Engineer" }
    department { "Engineering" }
    salary { 1_200_000 }
    employment_type { "full_time" }
    hire_date { Date.new(2022, 4, 1) }

    after(:build) do |employee, context|
      employee.country = Country.find_by(name: context.country)
    end
  end
end

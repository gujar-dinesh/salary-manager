require "rails_helper"

# Bulk inserts and raw SQL skip Rails validations, so the database has to hold the line on its own.
RSpec.describe "Database constraints" do
  let(:india) { Country.find_by!(name: "India") }
  let(:department) { Department.create!(name: "Engineering") }
  let(:job_title) { JobTitle.create!(name: "Engineer") }

  # Each attempt gets its own savepoint, because Postgres aborts the surrounding transaction on a violation.
  def raw_insert(model, row)
    model.transaction(requires_new: true) { model.insert_all!([ row ]) }
  end

  def employee_row(overrides = {})
    { full_name: "Raw Insert", email: "raw@acme.test", job_title_id: job_title.id, department_id: department.id,
      country_id: india.id, salary: 100, employment_type: "full_time", hire_date: "2024-01-01" }.merge(overrides)
  end

  it "treats emails that differ only in case as duplicates" do
    raw_insert(Employee, employee_row(email: "jane@acme.test"))

    expect { raw_insert(Employee, employee_row(email: "Jane@acme.test")) }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects an email without an @" do
    expect { raw_insert(Employee, employee_row(email: "not-an-email")) }.to raise_error(ActiveRecord::CheckViolation)
  end

  it "rejects blank or over-long names" do
    expect { raw_insert(Employee, employee_row(full_name: "  ")) }.to raise_error(ActiveRecord::CheckViolation)
    expect { raw_insert(Employee, employee_row(full_name: "a" * 101)) }.to raise_error(ActiveRecord::ValueTooLong)
    expect { raw_insert(JobTitle, { name: "" }) }.to raise_error(ActiveRecord::CheckViolation)
    expect { raw_insert(Department, { name: "a" * 101 }) }.to raise_error(ActiveRecord::ValueTooLong)
  end

  it "rejects malformed country and currency codes" do
    expect { raw_insert(Country, { code: "in", name: "Lowercase", currency: "INR" }) }
      .to raise_error(ActiveRecord::CheckViolation)
    expect { raw_insert(ExchangeRate, { currency: "us$", usd_rate: 1 }) }.to raise_error(ActiveRecord::CheckViolation)
  end

  it "rejects a non-positive exchange rate" do
    expect { raw_insert(ExchangeRate, { currency: "CHF", usd_rate: 0 }) }.to raise_error(ActiveRecord::CheckViolation)
  end

  it "only records salary history in a known currency" do
    employee = create(:employee)

    expect { raw_insert(SalaryChange, { employee_id: employee.id, old_salary: 1, new_salary: 2, old_currency: "XXX", new_currency: "INR" }) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end
end

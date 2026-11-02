require "rails_helper"

RSpec.describe Employee do
  it "is valid with the factory defaults" do
    expect(build(:employee)).to be_valid
  end

  %i[full_name email job_title department salary hire_date].each do |field|
    it "requires #{field}" do
      employee = build(:employee, field => nil)
      expect(employee).not_to be_valid
      expect(employee.errors[field]).to be_present
    end
  end

  it "rejects a malformed email" do
    expect(build(:employee, email: "not-an-email")).not_to be_valid
  end

  it "normalizes email and rejects duplicates regardless of case" do
    create(:employee, email: "jane@acme.test")
    duplicate = build(:employee, email: " JANE@acme.test ")

    expect(duplicate.email).to eq("jane@acme.test")
    expect(duplicate).not_to be_valid
  end

  it "requires a positive salary" do
    expect(build(:employee, salary: 0)).not_to be_valid
    expect(build(:employee, salary: -10)).not_to be_valid
  end

  it "rejects a salary larger than the column can store" do
    expect(build(:employee, salary: 10_000_000_000)).not_to be_valid
  end

  it "limits the length of text fields" do
    %i[full_name job_title department].each do |field|
      expect(build(:employee, field => "a" * 101)).not_to be_valid
    end
    expect(build(:employee, email: "#{"a" * 250}@acme.test")).not_to be_valid
  end

  it "requires a known country" do
    employee = build(:employee, country: "Atlantis")

    expect(employee).not_to be_valid
    expect(employee.errors[:country]).to be_present
  end

  it "takes its currency from the country" do
    expect(build(:employee, country: "Germany").currency).to eq("EUR")
    expect(build(:employee, country: "India").currency).to eq("INR")
  end

  it "only accepts known employment types" do
    expect(build(:employee, employment_type: "intern")).not_to be_valid
    expect(build(:employee, employment_type: "contractor")).to be_valid
  end

  it "exposes employment type helpers" do
    employee = build(:employee, employment_type: "contractor")

    expect(employee).to be_contractor
    expect(Employee.employment_types.keys).to eq(%w[full_time part_time contractor])
  end

  describe "database constraints" do
    let(:row) do
      { full_name: "Raw Insert", email: "raw@acme.test", job_title: "Engineer", department: "Engineering",
        country_id: Country.find_by!(name: "India").id, salary: 100, employment_type: "full_time", hire_date: "2024-01-01" }
    end

    it "rejects a non-positive salary even when validations are skipped" do
      expect { Employee.insert_all!([ row.merge(salary: 0) ]) }.to raise_error(ActiveRecord::CheckViolation)
    end

    it "rejects an unknown employment type even when validations are skipped" do
      expect { Employee.insert_all!([ row.merge(employment_type: "intern") ]) }.to raise_error(ActiveRecord::CheckViolation)
    end
  end

  it "rejects a hire date in the future" do
    expect(build(:employee, hire_date: Date.current + 1)).not_to be_valid
  end

  describe "salary history" do
    let(:employee) { create(:employee, salary: 1_000_000) }

    it "does not record a change when the employee is created" do
      expect(employee.salary_changes).to be_empty
    end

    it "records the old and new salary when the salary changes" do
      employee.update!(salary: 1_100_000)

      change = employee.salary_changes.sole
      expect(change.old_salary).to eq(1_000_000)
      expect(change.new_salary).to eq(1_100_000)
      expect(change.currency).to eq("INR")
    end

    it "does not record a change when other fields change" do
      employee.update!(job_title: "Senior Software Engineer")
      expect(employee.salary_changes).to be_empty
    end

    it "removes the history when the employee is deleted" do
      employee.update!(salary: 1_100_000)
      expect { employee.destroy }.to change(SalaryChange, :count).by(-1)
    end
  end
end

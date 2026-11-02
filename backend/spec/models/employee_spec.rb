require "rails_helper"

RSpec.describe Employee do
  it "is valid with the factory defaults" do
    expect(build(:employee)).to be_valid
  end

  %i[full_name email job_title department country salary hire_date].each do |field|
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

  it "only accepts supported countries" do
    expect(build(:employee, country: "Atlantis")).not_to be_valid
  end

  it "sets the currency from the country" do
    expect(build(:employee, country: "Germany").tap(&:valid?).currency).to eq("EUR")
    expect(build(:employee, country: "India").tap(&:valid?).currency).to eq("INR")
  end

  it "only accepts known employment types" do
    expect(build(:employee, employment_type: "intern")).not_to be_valid
    expect(build(:employee, employment_type: "contractor")).to be_valid
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

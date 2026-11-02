require "rails_helper"

RSpec.describe EmployeeSerializer do
  let(:employee) { create(:employee, salary: 100) }

  it "returns salary as a number and leaves out history by default" do
    json = described_class.new(employee).as_json

    expect(json["salary"]).to eq(100.0)
    expect(json).not_to have_key("salary_changes")
    expect(json.keys).not_to include("created_at", "updated_at")
  end

  it "includes salary history when asked" do
    employee.update!(salary: 120)

    json = described_class.new(employee, with_history: true).as_json

    expect(json["salary_changes"].first).to include(old_salary: 100.0, new_salary: 120.0)
  end
end

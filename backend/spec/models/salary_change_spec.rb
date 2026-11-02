require "rails_helper"

RSpec.describe SalaryChange do
  let(:employee) { create(:employee) }

  it "requires positive salaries and a currency" do
    change = employee.salary_changes.build(old_salary: 0, new_salary: nil, currency: nil)

    expect(change).not_to be_valid
    expect(change.errors.attribute_names).to contain_exactly(:old_salary, :new_salary, :currency)
  end

  it "cannot be changed once recorded" do
    change = employee.salary_changes.create!(old_salary: 100, new_salary: 120, currency: "INR")

    expect { change.update!(new_salary: 999) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { change.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end

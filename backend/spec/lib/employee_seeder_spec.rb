require "rails_helper"

RSpec.describe EmployeeSeeder do
  it "creates the requested number of valid employees" do
    described_class.new(count: 200).run

    expect(Employee.count).to eq(200)
    expect(Employee.all).to all(be_valid)
  end

  it "creates an exchange rate for every currency used" do
    described_class.new(count: 50).run

    expect(ExchangeRate.pluck(:currency)).to match_array(Employee::CURRENCY_BY_COUNTRY.values.uniq)
  end

  it "produces the same data on every run" do
    described_class.new(count: 20).run
    first_run = Employee.order(:email).pluck(:email, :country, :salary)

    described_class.new(count: 20).run
    expect(Employee.order(:email).pluck(:email, :country, :salary)).to eq(first_run)
  end

  it "replaces existing employees instead of adding to them" do
    create(:employee)
    described_class.new(count: 10).run

    expect(Employee.count).to eq(10)
  end
end

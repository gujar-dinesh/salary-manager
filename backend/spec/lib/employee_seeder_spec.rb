require "rails_helper"

RSpec.describe EmployeeSeeder do
  it "creates the requested number of valid employees" do
    described_class.new(count: 200).run

    expect(Employee.count).to eq(200)
    expect(Employee.all).to all(be_valid)
  end

  it "loads the reference countries and exchange rates" do
    described_class.new(count: 50).run

    expect(Country.count).to eq(ReferenceData::COUNTRIES.size)
    expect(ExchangeRate.pluck(:currency)).to match_array(ReferenceData::USD_RATES.keys)
  end

  it "produces the same data on every run" do
    described_class.new(count: 20).run
    first_run = Employee.order(:email).pluck(:email, :country_id, :salary)

    described_class.new(count: 20).run
    expect(Employee.order(:email).pluck(:email, :country_id, :salary)).to eq(first_run)
  end

  describe ".seed" do
    it "seeds an empty database in any environment" do
      expect(described_class.seed(environment: "production", count: 5)).to eq(:seeded)
      expect(Employee.count).to eq(5)
    end

    it "refuses to replace existing employees in production" do
      create(:employee)

      expect(described_class.seed(environment: "production", count: 5)).to eq(:skipped)
      expect(Employee.count).to eq(1)
    end

    it "replaces production data only when forced" do
      create(:employee)

      expect(described_class.seed(environment: "production", force: true, count: 5)).to eq(:seeded)
      expect(Employee.count).to eq(5)
    end

    it "always reseeds outside production" do
      create(:employee)

      expect(described_class.seed(environment: "development", count: 5)).to eq(:seeded)
    end
  end

  it "replaces existing employees instead of adding to them" do
    create(:employee)
    described_class.new(count: 10).run

    expect(Employee.count).to eq(10)
  end
end

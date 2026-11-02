require "rails_helper"

RSpec.describe PayrollReport do
  before do
    set_usd_rate("INR", 0.01)
    set_usd_rate("EUR", 1.1)
  end

  describe ".overview" do
    it "converts payroll to USD by country and department" do
      create(:employee, country: "India", department: "Engineering", salary: 1000)
      create(:employee, country: "India", department: "Sales", salary: 3000)
      create(:employee, country: "Germany", department: "Engineering", salary: 100)

      overview = described_class.overview

      expect(overview[:headcount]).to eq(3)
      expect(overview[:payroll_usd]).to eq(150.0)
      expect(overview[:by_country]).to eq([
        { group: "Germany", headcount: 1, payroll_usd: 110.0, average_usd: 110.0 },
        { group: "India", headcount: 2, payroll_usd: 40.0, average_usd: 20.0 }
      ])
      expect(overview[:by_department].first).to eq(group: "Engineering", headcount: 2, payroll_usd: 120.0,
                                                   average_usd: 60.0)
    end
  end

  describe "#totals_by" do
    it "only groups by known columns" do
      expect { described_class.new.totals_by(:email) }.to raise_error(ArgumentError)
    end
  end
end

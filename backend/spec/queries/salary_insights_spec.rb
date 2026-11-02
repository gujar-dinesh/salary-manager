require "rails_helper"

RSpec.describe SalaryInsights do
  describe ".by_country" do
    it "returns headcount and salary stats per country in local currency" do
      [ 100, 200, 600 ].each { |salary| create(:employee, country: "India", salary: salary) }
      [ 50, 70 ].each { |salary| create(:employee, country: "Germany", salary: salary) }

      result = described_class.by_country.index_by { |row| row[:group] }

      expect(result["India"]).to eq(group: "India", currency: "INR", headcount: 3, min: 100.0, max: 600.0,
                                    average: 300.0, median: 200.0)
      expect(result["Germany"]).to include(currency: "EUR", headcount: 2, median: 60.0)
    end

    it "returns nothing when there are no employees" do
      expect(described_class.by_country).to eq([])
    end
  end

  describe ".by_job_title" do
    it "returns stats per job title within the given country only" do
      create(:employee, country: "India", job_title: "Engineer", salary: 100)
      create(:employee, country: "India", job_title: "Engineer", salary: 300)
      create(:employee, country: "India", job_title: "Designer", salary: 80)
      create(:employee, country: "Germany", job_title: "Engineer", salary: 9999)

      result = described_class.by_job_title("India").index_by { |row| row[:group] }

      expect(result.keys).to contain_exactly("Engineer", "Designer")
      expect(result["Engineer"]).to include(headcount: 2, min: 100.0, max: 300.0, median: 200.0)
      expect(result["Designer"]).to include(headcount: 1, median: 80.0)
    end
  end

  describe ".stats" do
    it "computes the median for odd, even and single-value groups" do
      [ 10, 20, 30 ].each { |s| create(:employee, department: "Odd", salary: s) }
      [ 10, 20, 30, 100 ].each { |s| create(:employee, department: "Even", salary: s) }
      create(:employee, department: "Single", salary: 42)

      medians = described_class.stats(Employee.all, :department) { nil }.to_h { |row| [ row[:group], row[:median] ] }

      expect(medians).to eq("Even" => 25.0, "Odd" => 20.0, "Single" => 42.0)
    end
  end

  describe ".overview" do
    before do
      create(:exchange_rate, currency: "INR", usd_rate: 0.01)
      create(:exchange_rate, currency: "EUR", usd_rate: 1.1)
    end

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
end

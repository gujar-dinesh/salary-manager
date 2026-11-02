require "rails_helper"

RSpec.describe SalaryStatistics do
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

      result = described_class.by_job_title(Country.find_by!(name: "India")).index_by { |row| row[:group] }

      expect(result.keys).to contain_exactly("Engineer", "Designer")
      expect(result["Engineer"]).to include(currency: "INR", headcount: 2, min: 100.0, max: 300.0, median: 200.0)
      expect(result["Designer"]).to include(headcount: 1, median: 80.0)
    end
  end

  describe "#rows" do
    it "computes the median for odd, even and single-value groups" do
      [ 10, 20, 30 ].each { |s| create(:employee, department: "Odd", salary: s) }
      [ 10, 20, 30, 100 ].each { |s| create(:employee, department: "Even", salary: s) }
      create(:employee, department: "Single", salary: 42)

      medians = described_class.new(Employee.all, :department).rows.to_h { |row| [ row[:group], row[:median] ] }

      expect(medians).to eq("Even" => 25.0, "Odd" => 20.0, "Single" => 42.0)
    end

    it "only groups by known columns" do
      expect { described_class.new(Employee.all, :email) }.to raise_error(ArgumentError)
    end
  end
end

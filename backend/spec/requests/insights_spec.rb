require "rails_helper"

RSpec.describe "Insights API", type: :request do
  def json = response.parsed_body

  it "returns stats by country" do
    create(:employee, country: "India", salary: 100)

    get "/api/insights/countries"

    expect(json.first).to include("group" => "India", "headcount" => 1, "median" => 100.0)
  end

  it "returns stats by job title for a country" do
    create(:employee, country: "India", job_title: "Engineer", salary: 100)

    get "/api/insights/job_titles", params: { country: "India" }

    expect(json.first).to include("group" => "Engineer", "currency" => "INR")
  end

  it "requires a supported country for job title stats" do
    get "/api/insights/job_titles", params: { country: "Atlantis" }
    expect(response).to have_http_status(:bad_request)
  end

  it "returns the USD overview" do
    create(:exchange_rate, currency: "INR", usd_rate: 0.01)
    create(:employee, country: "India", salary: 1000)

    get "/api/insights/overview"

    expect(json).to include("headcount" => 1, "payroll_usd" => 10.0)
  end
end

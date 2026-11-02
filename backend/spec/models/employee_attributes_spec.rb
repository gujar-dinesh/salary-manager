require "rails_helper"

RSpec.describe EmployeeAttributes do
  it "resolves the country name to a record" do
    attributes = described_class.new(ActionController::Parameters.new(country: "Japan", full_name: "Ken").permit!).to_h

    expect(attributes).to eq(country: Country.find_by!(name: "Japan"), full_name: "Ken")
  end

  it "leaves the country out when it is not being changed" do
    attributes = described_class.new(ActionController::Parameters.new(salary: 10).permit!).to_h

    expect(attributes).to eq(salary: 10)
  end
end

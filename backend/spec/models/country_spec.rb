require "rails_helper"

RSpec.describe Country do
  it "is linked to the exchange rate for its currency" do
    expect(described_class.find_by!(name: "Germany").exchange_rate.currency).to eq("EUR")
  end

  it "requires a two-letter code and unique name" do
    country = described_class.new(code: "XYZ", name: "India", currency: "INR")

    expect(country).not_to be_valid
    expect(country.errors.attribute_names).to include(:code, :name)
  end

  it "cannot use a currency without an exchange rate" do
    expect { described_class.create!(code: "ZZ", name: "Zedland", currency: "ZZZ") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "cannot be deleted while employees belong to it" do
    country = create(:employee, country: "Japan").country

    expect(country.destroy).to be(false)
    expect(country.errors[:base]).to be_present
  end
end

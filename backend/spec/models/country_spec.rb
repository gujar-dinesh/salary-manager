require "rails_helper"

RSpec.describe Country do
  it "maps each supported country to its currency" do
    expect(described_class.currency_for("Germany")).to eq("EUR")
    expect(described_class.currency_for("India")).to eq("INR")
    expect(described_class.currency_for("Atlantis")).to be_nil
  end

  it "knows which countries are supported" do
    expect(described_class.supported?("Japan")).to be(true)
    expect(described_class.supported?("Atlantis")).to be(false)
  end

  it "lists each currency once" do
    expect(described_class.currencies.count("EUR")).to eq(1)
  end
end

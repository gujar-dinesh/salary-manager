module ReferenceData
  USD_RATES = {
    "USD" => 1.0, "EUR" => 1.08, "GBP" => 1.27, "INR" => 0.012, "CAD" => 0.73,
    "AUD" => 0.66, "SGD" => 0.74, "JPY" => 0.0067, "BRL" => 0.18
  }.freeze

  COUNTRIES = [
    { code: "AU", name: "Australia", currency: "AUD" },
    { code: "BR", name: "Brazil", currency: "BRL" },
    { code: "CA", name: "Canada", currency: "CAD" },
    { code: "FR", name: "France", currency: "EUR" },
    { code: "DE", name: "Germany", currency: "EUR" },
    { code: "IN", name: "India", currency: "INR" },
    { code: "JP", name: "Japan", currency: "JPY" },
    { code: "SG", name: "Singapore", currency: "SGD" },
    { code: "GB", name: "United Kingdom", currency: "GBP" },
    { code: "US", name: "United States", currency: "USD" }
  ].freeze

  def self.load
    ExchangeRate.upsert_all(USD_RATES.map { |currency, rate| { currency: currency, usd_rate: rate } }, unique_by: :currency)
    Country.upsert_all(COUNTRIES, unique_by: :code)
  end
end

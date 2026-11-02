module Country
  CURRENCIES = {
    "Australia" => "AUD",
    "Brazil" => "BRL",
    "Canada" => "CAD",
    "France" => "EUR",
    "Germany" => "EUR",
    "India" => "INR",
    "Japan" => "JPY",
    "Singapore" => "SGD",
    "United Kingdom" => "GBP",
    "United States" => "USD"
  }.freeze

  def self.names
    CURRENCIES.keys
  end

  def self.currencies
    CURRENCIES.values.uniq
  end

  def self.supported?(name)
    CURRENCIES.key?(name)
  end

  def self.currency_for(name)
    CURRENCIES[name]
  end
end

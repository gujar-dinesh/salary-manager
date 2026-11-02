module ExchangeRateHelpers
  def set_usd_rate(currency, rate)
    ExchangeRate.find_by!(currency: currency).update!(usd_rate: rate)
  end
end

RSpec.configure do |config|
  config.include ExchangeRateHelpers
end

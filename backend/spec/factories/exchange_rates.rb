FactoryBot.define do
  factory :exchange_rate do
    currency { "INR" }
    usd_rate { 0.012 }
  end
end

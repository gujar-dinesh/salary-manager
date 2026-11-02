class ExchangeRate < ApplicationRecord
  validates :currency, presence: true, uniqueness: true
  validates :usd_rate, presence: true, numericality: { greater_than: 0 }
end

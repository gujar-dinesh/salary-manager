class ExchangeRate < ApplicationRecord
  has_many :countries, foreign_key: :currency, primary_key: :currency, dependent: :restrict_with_error

  validates :currency, presence: true, uniqueness: true
  validates :usd_rate, presence: true, numericality: { greater_than: 0 }
end

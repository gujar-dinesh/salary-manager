class Country < ApplicationRecord
  include CaseInsensitiveName

  belongs_to :exchange_rate, foreign_key: :currency, primary_key: :currency
  has_many :employees, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true, uniqueness: true
end

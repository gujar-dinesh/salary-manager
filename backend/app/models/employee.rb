class Employee < ApplicationRecord
  USD_SALARY = "employees.salary * exchange_rates.usd_rate".freeze

  enum :employment_type, { full_time: "full_time", part_time: "part_time", contractor: "contractor" }, validate: true

  belongs_to :country
  belongs_to :department, validate: true
  belongs_to :job_title, validate: true
  has_one :exchange_rate, through: :country
  has_many :salary_changes, -> { order(created_at: :desc, id: :desc) }, dependent: :delete_all

  scope :with_usd_salary, -> { joins(country: :exchange_rate) }

  delegate :currency, to: :country, allow_nil: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, with: ->(value) { value.squish }

  validates :full_name, presence: true, length: { maximum: 100 }
  validates :hire_date, presence: true
  validates :email, presence: true, uniqueness: true, length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :salary, presence: true, numericality: { greater_than: 0, less_than: 10_000_000_000 }
  validate :hire_date_not_in_future

  after_update :record_salary_change, if: -> { saved_change_to_salary? || saved_change_to_country_id? }

  private

  def hire_date_not_in_future
    errors.add(:hire_date, "can't be in the future") if hire_date&.future?
  end

  # Pay changes when the amount or its currency changes; a move between countries that share a
  # currency with the same amount is not a pay change.
  def record_salary_change
    old_currency = saved_change_to_country_id? ? Country.find(country_id_before_last_save).currency : currency
    return if salary_before_last_save == salary && old_currency == currency

    salary_changes.create!(old_salary: salary_before_last_save, new_salary: salary,
                           old_currency: old_currency, new_currency: currency)
  end
end

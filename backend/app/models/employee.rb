class Employee < ApplicationRecord
  EMPLOYMENT_TYPES = %w[full_time part_time contractor].freeze
  USD_SALARY = "employees.salary * exchange_rates.usd_rate".freeze

  has_many :salary_changes, -> { order(created_at: :desc, id: :desc) }, dependent: :delete_all

  scope :with_usd_salary, -> {
    select("employees.*").joins("LEFT JOIN exchange_rates ON exchange_rates.currency = employees.currency")
  }

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, :job_title, :department, with: ->(value) { value.squish }

  validates :full_name, :job_title, :department, presence: true, length: { maximum: 100 }
  validates :hire_date, presence: true
  validates :email, presence: true, uniqueness: true, length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, presence: true, inclusion: { in: Country.names }
  validates :salary, presence: true, numericality: { greater_than: 0, less_than: 10_000_000_000 }
  validates :employment_type, inclusion: { in: EMPLOYMENT_TYPES }
  validate :hire_date_not_in_future

  before_validation :set_currency
  after_update :record_salary_change, if: :saved_change_to_salary?

  private

  def set_currency
    self.currency = Country.currency_for(country)
  end

  def hire_date_not_in_future
    errors.add(:hire_date, "can't be in the future") if hire_date&.future?
  end

  def record_salary_change
    old_salary, new_salary = saved_change_to_salary
    salary_changes.create!(old_salary: old_salary, new_salary: new_salary, currency: currency)
  end
end

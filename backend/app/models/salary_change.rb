class SalaryChange < ApplicationRecord
  belongs_to :employee

  validates :old_salary, :new_salary, presence: true, numericality: { greater_than: 0 }
  validates :old_currency, :new_currency, presence: true

  # Audit rows are append-only.
  def readonly?
    persisted?
  end
end

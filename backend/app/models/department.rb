class Department < ApplicationRecord
  include NamedLookup

  has_many :employees, dependent: :restrict_with_error
end

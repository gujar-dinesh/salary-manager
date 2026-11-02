class JobTitle < ApplicationRecord
  include NamedLookup

  has_many :employees, dependent: :restrict_with_error
end

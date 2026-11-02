# Reference data identified by a case-insensitive unique name, e.g. departments and job titles.
module NamedLookup
  extend ActiveSupport::Concern

  included do
    normalizes :name, with: ->(name) { name.squish }

    validates :name, presence: true, length: { maximum: 100 }
    validates :name, uniqueness: { case_sensitive: false }
  end

  class_methods do
    # Returns the record with this name, creating it if needed. Call inside the transaction that saves the
    # employee, so a new name is rolled back if the employee turns out to be invalid.
    def named(name)
      name = name.to_s.squish
      return if name.empty?

      find_named(name) || create_named(name)
    end

    def find_named(name)
      where("LOWER(name) = LOWER(?)", name).first
    end

    private

    # Parallel requests may add the same new name at once. The unique index picks the winner and the
    # others read the winner's row. An invalid name comes back unsaved so the employee reports the error.
    def create_named(name)
      record = new(name: name)
      transaction(requires_new: true) { record.save! }
      record
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      find_named(name) || record
    end
  end
end

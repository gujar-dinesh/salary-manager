# Reference data identified by a case-insensitive unique name, e.g. departments and job titles.
module NamedLookup
  extend ActiveSupport::Concern

  included do
    normalizes :name, with: ->(name) { name.squish }

    validates :name, presence: true, length: { maximum: 100 }
    validates :name, uniqueness: { case_sensitive: false }
  end

  class_methods do
    # Returns the existing record with this name, or an unsaved new one that is
    # saved together with the employee that references it.
    def named(name)
      name = name.to_s.squish
      return if name.empty?

      where("LOWER(name) = LOWER(?)", name).first || new(name: name)
    end
  end
end

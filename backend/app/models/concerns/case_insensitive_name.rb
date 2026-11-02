# Reference rows are found by name ignoring case, everywhere a name comes from a user or a URL.
module CaseInsensitiveName
  extend ActiveSupport::Concern

  included do
    scope :with_name, ->(name) { where("LOWER(name) = LOWER(?)", name.to_s.squish) }
  end

  class_methods do
    def find_named(name)
      with_name(name).first
    end
  end
end

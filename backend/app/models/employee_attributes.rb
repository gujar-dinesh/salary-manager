# Turns API params, which use names for reference data, into model attributes.
class EmployeeAttributes
  def initialize(params)
    @params = params
  end

  def to_h
    attributes = @params.to_h.symbolize_keys
    attributes[:country] = Country.find_by(name: attributes[:country]) if attributes.key?(:country)
    attributes
  end
end

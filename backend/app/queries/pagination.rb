class Pagination
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  attr_reader :page, :per_page

  def initialize(page:, per_page:)
    @page = [ page.to_i, 1 ].max
    @per_page = per_page.present? ? per_page.to_i.clamp(1, MAX_PER_PAGE) : DEFAULT_PER_PAGE
  end

  def apply(scope)
    scope.limit(per_page).offset((page - 1) * per_page)
  end

  def meta(total)
    { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil }
  end
end

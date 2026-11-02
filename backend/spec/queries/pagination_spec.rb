require "rails_helper"

RSpec.describe Pagination do
  it "defaults to the first page of 25" do
    pagination = described_class.new(page: nil, per_page: nil)

    expect(pagination.page).to eq(1)
    expect(pagination.per_page).to eq(25)
  end

  it "keeps page and page size within bounds" do
    expect(described_class.new(page: "-3", per_page: "0").page).to eq(1)
    expect(described_class.new(page: "1", per_page: "0").per_page).to eq(1)
    expect(described_class.new(page: "1", per_page: "5000").per_page).to eq(100)
    expect(described_class.new(page: "99999999999999999999", per_page: nil).page).to eq(Pagination::MAX_PAGE)
  end

  it "builds the meta block from a total" do
    meta = described_class.new(page: "2", per_page: "10").meta(25)

    expect(meta).to eq(page: 2, per_page: 10, total: 25, total_pages: 3)
  end

  it "applies limit and offset to a scope" do
    create_list(:employee, 5)
    page = described_class.new(page: "2", per_page: "2").apply(Employee.order(:id))

    expect(page.map(&:id)).to eq(Employee.order(:id).offset(2).limit(2).map(&:id))
  end
end

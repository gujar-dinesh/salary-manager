require "rails_helper"

# These specs recreate races deterministically: the competing row is committed first, and our
# request is made to miss it at exactly the point where a real parallel request would.
RSpec.describe "Employees API under concurrent writes", type: :request do
  def json = response.parsed_body

  let(:params) do
    { employee: attributes_for(:employee).merge(country: "India", department: "Engineering", job_title: "Staff Engineer") }
  end

  def skip_uniqueness_check_once(model, attribute)
    skipped = false
    allow_any_instance_of(ActiveRecord::Validations::UniquenessValidator)
      .to receive(:validate_each).and_wrap_original do |original, record, attr, value|
        if record.is_a?(model) && attr == attribute && !skipped
          skipped = true
        else
          original.call(record, attr, value)
        end
      end
  end

  def miss_existing_lookup_once(model)
    missed = false
    allow(model).to receive(:find_named).and_wrap_original do |original, name|
      missed ? original.call(name) : (missed = true) && nil
    end
  end

  it "reuses a job title that a parallel request inserted after our lookup" do
    competitor = JobTitle.create!(name: "Staff Engineer")
    miss_existing_lookup_once(JobTitle)
    skip_uniqueness_check_once(JobTitle, :name)

    post "/api/employees", params: params

    expect(response).to have_http_status(:created)
    expect(JobTitle.where("LOWER(name) = 'staff engineer'").pluck(:id)).to eq([ competitor.id ])
  end

  it "reuses a job title that a parallel request inserted before our validation" do
    competitor = JobTitle.create!(name: "Staff Engineer")
    miss_existing_lookup_once(JobTitle)

    post "/api/employees", params: params

    expect(response).to have_http_status(:created)
    expect(Employee.last.job_title).to eq(competitor)
  end

  it "does not leave a new job title behind when the employee is invalid" do
    post "/api/employees", params: { employee: params[:employee].merge(email: "bad") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(JobTitle.where(name: "Staff Engineer")).to be_empty
  end

  it "returns a validation error when a parallel request saved the same email first" do
    create(:employee, email: "race@acme.test")
    skip_uniqueness_check_once(Employee, :email)

    post "/api/employees", params: { employee: params[:employee].merge(email: "race@acme.test") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]["email"]).to include("has already been taken")
  end

  it "returns 409 instead of 500 if the conflict persists" do
    allow_any_instance_of(Employee).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

    post "/api/employees", params: params

    expect(response).to have_http_status(:conflict)
  end
end

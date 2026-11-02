require "rails_helper"

RSpec.describe "Employees API", type: :request do
  def json = response.parsed_body

  describe "GET /api/employees" do
    it "returns a page of employees with pagination info" do
      create_list(:employee, 3)

      get "/api/employees", params: { per_page: 2, page: 2 }

      expect(response).to have_http_status(:ok)
      expect(json["employees"].size).to eq(1)
      expect(json["meta"]).to eq("page" => 2, "per_page" => 2, "total" => 3, "total_pages" => 2)
    end

    it "searches by name or email" do
      create(:employee, full_name: "Asha Rao", email: "asha@acme.test")
      create(:employee, full_name: "Ben Stone", email: "ben.r@acme.test")

      get "/api/employees", params: { q: "asha" }
      expect(json["employees"].map { |e| e["full_name"] }).to eq([ "Asha Rao" ])

      get "/api/employees", params: { q: "ben.r" }
      expect(json["employees"].map { |e| e["full_name"] }).to eq([ "Ben Stone" ])

      get "/api/employees", params: { q: "ASHA" }
      expect(json["employees"].map { |e| e["full_name"] }).to eq([ "Asha Rao" ])
    end

    it "filters by country, department and job title" do
      create(:employee, full_name: "Match", country: "Germany", department: "Sales", job_title: "Account Executive")
      create(:employee, country: "Germany", department: "Engineering")
      create(:employee, country: "India", department: "Sales", job_title: "Account Executive")

      get "/api/employees", params: { country: "Germany", department: "Sales", job_title: "Account Executive" }

      expect(json["employees"].map { |e| e["full_name"] }).to eq([ "Match" ])
    end

    it "sorts by salary within a country" do
      create(:employee, full_name: "Low", salary: 100)
      create(:employee, full_name: "High", salary: 300)
      create(:employee, full_name: "Mid", salary: 200)

      get "/api/employees", params: { country: "India", sort: "salary", direction: "desc" }

      expect(json["employees"].map { |e| e["full_name"] }).to eq(%w[High Mid Low])
    end

    it "sorts by the USD equivalent when employees are in different currencies" do
      create(:employee, full_name: "Mumbai", country: "India", salary: 2_000_000)
      create(:employee, full_name: "Austin", country: "United States", salary: 90_000)

      get "/api/employees", params: { sort: "salary", direction: "desc" }

      expect(json["employees"].map { |e| e["full_name"] }).to eq(%w[Austin Mumbai])
    end

    it "ignores unknown sort columns" do
      create(:employee, full_name: "B")
      create(:employee, full_name: "A")

      get "/api/employees", params: { sort: "salary; DROP TABLE employees" }

      expect(response).to have_http_status(:ok)
      expect(json["employees"].map { |e| e["full_name"] }).to eq(%w[A B])
    end

    it "ignores an overly long search term" do
      create(:employee, full_name: "Asha Rao")

      get "/api/employees", params: { q: "a" * 500 }

      expect(response).to have_http_status(:ok)
      expect(json["employees"]).to be_empty
    end

    it "matches filter names regardless of case" do
      create(:employee, full_name: "Match", country: "Germany", department: "Sales", job_title: "Account Executive")

      get "/api/employees", params: { country: "germany", department: "SALES", job_title: "account executive" }

      expect(json["employees"].map { |e| e["full_name"] }).to eq([ "Match" ])
    end

    it "handles an absurdly large page number" do
      create(:employee)

      get "/api/employees", params: { page: "99999999999999999999" }

      expect(response).to have_http_status(:ok)
      expect(json["employees"]).to be_empty
    end

    it "ignores parameters sent as arrays or hashes instead of failing" do
      create(:employee)

      get "/api/employees?q[]=x&per_page[]=5&sort[a]=b&page[]=2"

      expect(response).to have_http_status(:ok)
      expect(json["employees"].size).to eq(1)
      expect(json["meta"]["per_page"]).to eq(25)
    end

    it "caps the page size" do
      get "/api/employees", params: { per_page: 5000 }
      expect(json["meta"]["per_page"]).to eq(100)
    end
  end

  describe "GET /api/employees/:id" do
    it "returns the employee with salary history, newest first" do
      employee = create(:employee, salary: 100)
      employee.update!(salary: 110)
      employee.update!(salary: 120)

      get "/api/employees/#{employee.id}"

      expect(json["salary"]).to eq(120.0)
      expect(json["salary_changes"].map { |c| c["new_salary"] }).to eq([ 120.0, 110.0 ])
    end

    it "returns 404 for an unknown employee" do
      get "/api/employees/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/employees" do
    let(:params) do
      {
        employee: {
          full_name: "Priya Shah", email: "priya@acme.test", job_title: "Data Analyst",
          department: "Finance", country: "India", salary: 900000,
          employment_type: "full_time", hire_date: "2023-01-15"
        }
      }
    end

    it "creates an employee" do
      expect { post "/api/employees", params: params }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("full_name" => "Priya Shah", "currency" => "INR", "salary" => 900000.0)
    end

    it "returns validation errors" do
      post "/api/employees", params: { employee: params[:employee].merge(email: "bad", salary: -1) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to contain_exactly("email", "salary")
    end
  end

  it "reuses an existing department and job title regardless of case" do
    create(:employee, department: "Engineering", job_title: "Software Engineer")

    expect {
      post "/api/employees", params: { employee: attributes_for(:employee).merge(country: "India", department: " engineering ",
                                                                                job_title: "SOFTWARE ENGINEER") }
    }.not_to change { [ Department.count, JobTitle.count ] }

    expect(json).to include("department" => "Engineering", "job_title" => "Software Engineer")
  end

  it "creates a job title that does not exist yet" do
    post "/api/employees", params: { employee: attributes_for(:employee).merge(country: "India", department: "Engineering",
                                                                              job_title: "Staff Engineer") }

    expect(response).to have_http_status(:created)
    expect(JobTitle.pluck(:name)).to include("Staff Engineer")
  end

  it "accepts a country name in any case" do
    post "/api/employees", params: { employee: attributes_for(:employee).merge(country: "india", department: "Engineering",
                                                                              job_title: "Software Engineer") }

    expect(response).to have_http_status(:created)
    expect(json["country"]).to eq("India")
  end

  it "rejects an unknown country" do
    post "/api/employees", params: { employee: attributes_for(:employee).merge(country: "Atlantis") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("country")
  end

  describe "PATCH /api/employees/:id" do
    it "updates the employee and records the salary change" do
      employee = create(:employee, salary: 100)

      patch "/api/employees/#{employee.id}", params: { employee: { salary: 150 } }

      expect(response).to have_http_status(:ok)
      expect(json["salary"]).to eq(150.0)
      expect(json["salary_changes"].first).to include("old_salary" => 100.0, "new_salary" => 150.0)
    end
  end

  it "returns 400 when the employee params are missing" do
    post "/api/employees", params: { name: "x" }
    expect(response).to have_http_status(:bad_request)
  end

  describe "editing the same employee at the same time" do
    it "rejects a save based on an outdated version" do
      employee = create(:employee, salary: 100)
      loaded_version = employee.lock_version
      employee.update!(salary: 120)

      patch "/api/employees/#{employee.id}", params: { employee: { department: "Sales", salary: 100, lock_version: loaded_version } }

      expect(response).to have_http_status(:conflict)
      expect(employee.reload.salary).to eq(120)
      expect(employee.salary_changes.count).to eq(1)
    end

    it "treats a blank version as not sent" do
      employee = create(:employee)

      patch "/api/employees/#{employee.id}", params: { employee: { department: "Sales", lock_version: "" } }

      expect(response).to have_http_status(:ok)
      expect(json["department"]).to eq("Sales")
    end

    it "returns the current version so the next save can use it" do
      employee = create(:employee)

      patch "/api/employees/#{employee.id}", params: { employee: { salary: 150, lock_version: employee.lock_version } }

      expect(response).to have_http_status(:ok)
      expect(json["lock_version"]).to eq(employee.lock_version + 1)
    end
  end

  describe "DELETE /api/employees/:id" do
    it "deletes the employee" do
      employee = create(:employee)

      expect { delete "/api/employees/#{employee.id}" }.to change(Employee, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/employees/options" do
    it "lists values for the filters and form" do
      create(:employee, department: "Sales", job_title: "Account Executive")
      create(:employee, department: "Engineering", job_title: "Software Engineer")

      get "/api/employees/options"

      expect(json["countries"]).to include("India", "Germany")
      expect(json["departments"]).to eq(%w[Engineering Sales])
      expect(json["job_titles"]).to eq([ "Account Executive", "Software Engineer" ])
      expect(json["employment_types"]).to eq(%w[full_time part_time contractor])
    end
  end
end

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
    end

    it "filters by country, department and job title" do
      create(:employee, full_name: "Match", country: "Germany", department: "Sales", job_title: "Account Executive")
      create(:employee, country: "Germany", department: "Engineering")
      create(:employee, country: "India", department: "Sales", job_title: "Account Executive")

      get "/api/employees", params: { country: "Germany", department: "Sales", job_title: "Account Executive" }

      expect(json["employees"].map { |e| e["full_name"] }).to eq([ "Match" ])
    end

    it "sorts by salary descending" do
      create(:employee, full_name: "Low", salary: 100)
      create(:employee, full_name: "High", salary: 300)
      create(:employee, full_name: "Mid", salary: 200)

      get "/api/employees", params: { sort: "salary", direction: "desc" }

      expect(json["employees"].map { |e| e["full_name"] }).to eq(%w[High Mid Low])
    end

    it "ignores unknown sort columns" do
      create(:employee, full_name: "B")
      create(:employee, full_name: "A")

      get "/api/employees", params: { sort: "salary; DROP TABLE employees" }

      expect(response).to have_http_status(:ok)
      expect(json["employees"].map { |e| e["full_name"] }).to eq(%w[A B])
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

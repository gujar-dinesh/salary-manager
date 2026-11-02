require "rails_helper"

RSpec.describe "Serving the built frontend", type: :request do
  around do |example|
    Dir.mktmpdir do |dir|
      index = File.join(dir, "index.html")
      File.write(index, "<html><body>Salary Manager</body></html>")
      original = Rails.configuration.x.frontend_index
      Rails.configuration.x.frontend_index = index
      example.run
    ensure
      Rails.configuration.x.frontend_index = original
    end
  end

  it "serves the app for the root and for deep links, without long caching" do
    [ "/", "/employees/12", "/insights" ].each do |path|
      get path, headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Salary Manager")
      expect(response.headers["Cache-Control"]).to include("no-cache")
    end
  end

  it "serves deep links to clients that accept anything" do
    get "/employees/12", headers: { "Accept" => "*/*" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Salary Manager")
  end

  it "does not answer missing asset files with the app" do
    get "/assets/missing.js", headers: { "Accept" => "*/*" }

    expect(response).to have_http_status(:not_found)
  end

  it "leaves unknown API paths as JSON 404s" do
    get "/api/nothing-here"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Salary Manager")
  end

  it "returns 404 when the frontend has not been built" do
    Rails.configuration.x.frontend_index = "/missing/index.html"

    get "/employees/12", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_found)
  end
end

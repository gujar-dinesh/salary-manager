# Serves the built React app for the root path and client-side routes like /employees/12.
# index.html is never cached long, so a deploy is picked up at once; hashed assets in public/ are.
class FrontendController < ActionController::API
  def index
    path = Rails.configuration.x.frontend_index.to_s
    return head :not_found unless File.file?(path)

    response.headers["Cache-Control"] = "no-cache"
    send_file path, type: "text/html", disposition: "inline"
  end
end

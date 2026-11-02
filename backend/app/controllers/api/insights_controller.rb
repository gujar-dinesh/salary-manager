module Api
  class InsightsController < ApplicationController
    def countries
      render json: SalaryInsights.by_country
    end

    def job_titles
      unless Employee::CURRENCY_BY_COUNTRY.key?(params[:country])
        return render json: { error: "Unknown country" }, status: :bad_request
      end

      render json: SalaryInsights.by_job_title(params[:country])
    end

    def overview
      render json: SalaryInsights.overview
    end
  end
end

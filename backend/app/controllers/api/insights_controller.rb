module Api
  class InsightsController < ApplicationController
    def countries
      render json: SalaryStatistics.by_country
    end

    def job_titles
      country = Country.find_by(name: params[:country])
      return render json: { error: "Unknown country" }, status: :bad_request unless country

      render json: SalaryStatistics.by_job_title(country)
    end

    def overview
      render json: PayrollReport.overview
    end
  end
end

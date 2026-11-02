module Api
  class InsightsController < ApplicationController
    def countries
      render json: SalaryStatistics.by_country
    end

    def job_titles
      return render json: { error: "Unknown country" }, status: :bad_request unless Country.supported?(params[:country])

      render json: SalaryStatistics.by_job_title(params[:country])
    end

    def overview
      render json: PayrollReport.overview
    end
  end
end

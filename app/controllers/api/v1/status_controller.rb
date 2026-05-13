# frozen_string_literal: true

module Api
  module V1
    class StatusController < ActionController::API
      def show
        render json: {
          service: "ddd-eds-expense-split",
          status: "ok",
          api_version: "v1"
        }
      end
    end
  end
end

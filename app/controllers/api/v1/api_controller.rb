module Api
  module V1
    class ApiController < ::ApplicationController
      respond_to :json
      before_action :doorkeeper_authorize!
      skip_before_filter :verify_authenticity_token

      def current_application_id
        @current_application_id ||= doorkeeper_token.application_id.to_s
      end
    end
  end
end

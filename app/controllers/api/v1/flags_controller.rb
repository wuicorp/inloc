module Api
  module V1
    class FlagsController < ApiController
      def index
        with_valid_search_parameters do |longitude, latitude|
          flags = flags_map.find_flags_by_position(longitude, latitude)
          render json: { data: flags },
                 status: 200
        end
      end

      def create
        flags_map.add_flag(flag_params)
        if flags_map.save
          render json: flag_params, status: 201
        else
          render json: { errors: flags_map.errors.as_json }, status: 422
        end
      end

      def destroy
        if flags_map.remove_flag(params[:id])
          render json: {}, status: 200
        else
          render json: { detail: 'not found' }, status: 404
        end
      end

      private

      def flags_map
        @flags_map ||=
          FlagsMap.find_or_create_by(application_id: current_application_id)
      end

      def flag_params
        params.permit(:id, :latitude, :longitude, :radius)
      end

      def with_valid_search_parameters
        if valid_search_point?
          yield(latitude, longitude)
        else
          render json: { detail: 'invalid parameters' }, status: 422
        end
      end

      def longitude
        @longitude ||= flag_params[:longitude]
      end

      def latitude
        @latitude ||= flag_params[:latitude]
      end

      def valid_search_point?
        begin Float(longitude) rescue return false end
        begin Float(latitude) rescue return false end
        true
      end
    end
  end
end

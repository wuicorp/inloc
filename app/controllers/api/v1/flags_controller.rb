module Api
  module V1
    class FlagsController < ApiController
      def create
        flags_map.add_flag(flag_params)
        if flags_map.save
          render json: flag_params, status: 201
        else
          render json: { errors: flags_map.errors.as_json }, status: 422
        end
      end

      def destroy
        flags_map.remove_flag(params[:id])
        render json: {}, status: 200
      end

      private

      def flags_map
        @flags_map ||=
          FlagsMap.find_or_create_by(application_id: current_application_id)
      end

      def flag_params
        params.permit(:id, :latitude, :longitude, :radius)
      end
    end
  end
end

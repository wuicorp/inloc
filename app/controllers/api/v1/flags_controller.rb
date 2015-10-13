module Api
  module V1
    class FlagsController < ApiController
      def index
        with_valid_search_parameters do |longitude, latitude|
          if current_cell.present?
            render json: current_cell.flags,
                   status: 200
          else
            render json: { errors: [{ id: params[:code], title: 'not found' }] },
                   status: 404
          end
        end
      end

      def create
        @flag = Flag.create(flag_params)
        if @flag.valid?
          render json: @flag, status: 201
        else
          render json: ErrorSerializer.serialize(@flag.errors), status: 422
        end
      end

      def destroy
        if current_flag.present?
          current_flag.destroy
          render json: {}, status: 200
        else
          render json: { errors: [{ id: params[:id], title: 'not found' }] },
                 status: 404
        end
      end

      private

      def current_flag
        @flag ||= Flag.for_application_id(current_application_id).find_by(id: params[:id])
      end

      def current_cell
        @current_cell ||= Cell.at(longitude, latitude)
      end

      def flag_params
        params.permit(:code, :latitude, :longitude, :radius)
          .merge(application_id: current_application_id)
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

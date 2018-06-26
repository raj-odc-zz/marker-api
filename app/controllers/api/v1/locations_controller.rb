module Api::V1
  class LocationsController < ApplicationController
    require 'net/http'
    require 'net/https'
    require 'uri'

    before_action :set_location, only: [:show, :update, :destroy]

    rescue_from StandardError do |e|
      Rails.logger.error({ tag: 'StandardError', params: params, message: e }) 
      render json: { message: e.message, status: 'failure' }, status: :internal_server_error
    end

    # GET /locations
    def index
      @locations = Location.all.order(updated_at: :desc)

      render json: { locations: @locations, status: 'success', message: "Address retrieved successfully" },
             status: 200
    end

    # POST /locations
    def create
      api_response = build_json_params

      render api_response
    end

    # PATCH/PUT /locations/1
    def update
      api_response = build_json_params

      render api_response
    end

    # DELETE /locations/1
    def destroy
      if @location.destroy
        render json: { status: 'success', message: "Address deleted successfully" },
             status: 200
      else
        render json: { status: 'failure', message: "Something went wrong, please try again" },
            status: 422
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_location
        @location = Location.find(params[:id])
      end
      
      def execute_map_api(options)
        url = URI.parse(MAP_CONFIG['url'] + "?key=#{MAP_CONFIG['key']}&address=#{options[:address]}")
        
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(url.request_uri)
        request["Content-Type"]="application/json"

        http.request(request)  
      end

      def construct_params(response)
        params = {}

        if response['results'].present?
          address = response['results'][0]['address_components']
          params['long_name'] = address[0]['long_name']
          params['short_name'] = address[0]['short_name']
          geometry = response['results'][0]['geometry']
          params['latitude'] = geometry['location']["lat"]
          params['longitude'] = geometry['location']["lng"]
        end

        params
      end

      def create_update_location(params)
        if @location.blank?
          @location = Location.new(params)
          message = "Address added successfully"
          status  = 201
        else
          @location.attributes = params
          message = "Address updated successfully"
          status = 200
        end

        if @location.save
          api_response = { 
            json: { locations: @location, status: 'success', message: message },
            status: status
          }
        else
          api_response = { 
            json: { message: @location.errors, status: 'failure' }, 
            status: :unprocessable_entity 
          }
        end

        api_response
      end

      def build_json_params
        begin
          response = execute_map_api({address: params['address']}) if params['address'].present?
          parsed_response = JSON.parse(response.body) if response && response.code == "200"

          if parsed_response && parsed_response["results"].present? 
            location_params = construct_params(parsed_response)
            api_response = create_update_location(location_params)

          elsif (response && response.code == "404" || parsed_response.blank? || (parsed_response && parsed_response["results"].empty?))
            api_response = { 
              json: { status: 'failure', message: "Address not found, please enter valid address" },
              status: :not_found
            }

          else 
            api_response = { 
              json: { status: 'failure', message: "Something went wrong, please try again" },
              status: :unprocessable_entity
            }
          end

        rescue Exception => e
          Rails.logger.error({ tag: 'Google Map Api Error', params: params, message: e })
        end

        api_response
      end
  end
end

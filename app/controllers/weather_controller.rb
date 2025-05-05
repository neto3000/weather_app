class WeatherController < ApplicationController
  # before_action :validate_params
  before_action :inti_weather_provider
  before_action :inti_weather_service


  def index
    # first load with browser-geo will hit #show - this is done by the weather_controller.js
  end

  def show
    weather_reading = @weather_service.fetch(weather_service_params)

    render json: JSON.parse(weather_reading.payload), status: :ok
  end

  private

  def inti_weather_service
    @weather_service = WeatherService.new(@provider)
  end

  def inti_weather_provider
    @provider = params[:provider_name].present? ? Provider.find(name: params[:provider_name]) : Provider.default

  rescue ActiveRecord::RecordNotFound => e
    render json: { message: 'Provider not supported' }, status: :not_found
  end

  def validate_params
    if params[:lat].present?
      render json: { message: 'Wrong number of params' }, status: :bad_request if params[:lat].blank? || params[:lon].blank?
    elsif params[:city].blank?
      render json: { message: 'Wrong number of params' }, status: :bad_request
    end
  end

  def weather_service_params
    params.permit( :city, :state, :country, :zip_code, :lat, :lon)
  end
end

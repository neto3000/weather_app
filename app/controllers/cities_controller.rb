class CitiesController < ApplicationController
  def search
    render json: CitySearchService.call(query: params[:q].to_s.strip)
  end
end

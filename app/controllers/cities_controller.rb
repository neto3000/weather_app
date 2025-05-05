class CitiesController < ApplicationController
  def search
    # TODO : WIP
    render json: CitySearchService.call(q: params[:q].to_s.strip)
  end
end

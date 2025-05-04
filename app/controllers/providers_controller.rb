class ProvidersController < ApplicationController

  def index
    providers = Provider.all

    render json: prettify(providers)
  end

  private

  def prettify(providers)
    providers.map do | provider |
      {
          name:  provider.name,
          url:   provider.base_url,
      }
    end
  end
end

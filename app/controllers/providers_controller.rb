class ProvidersController < ApplicationController

  def index
    @providers = Provider.all

    respond_to do | format |
      format.json { render json: { data: prettify(@providers) }, status: :ok }
      format.html
    end
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

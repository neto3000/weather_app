class CitySearchService
  # TODO : WIP
  BASE      = ""
  LIMIT     = 5
  CACHE_TTL = 1.hour

  def self.call(search)
    return [] if search.blank?

    # TODO : WIP - Open account on https://rapidapi.com/
    Rails.cache.fetch("city_search/#{search.downcase}", expires_in: CACHE_TTL) do
      res   = Faraday.get()
      json  = JSON.parse(res.body)
      json.map { |c|
        {
            name:  c["name"],
            state: c["state"],
            lat:   c["lat"],
            lon:   c["lon"]
        }
      }
    end
  end
end

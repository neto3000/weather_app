class CitySearchService
  # TODO : WIP
  BASE       = "https://nominatim.openstreetmap.org/search".freeze
  LIMIT      = 7
  CACHE_TTL  = 1.hour
  USER_AGENT = ENV.fetch("NOMINATIM_USER_AGENT", "RailsWeatherApp (contact@example.com)")

  def self.call(query:)
    return [] if query.blank?

    Rails.cache.fetch("city_search/#{query.downcase}", expires_in: CACHE_TTL) do
      response = Faraday.get(BASE, {
          q: query,
          format: "json",
          addressdetails: 1,
          countrycodes: "us",   # comment this would make it worldwide
          limit: LIMIT
      }, { "User-Agent" => USER_AGENT })

      JSON.parse(response.body).map { |row| humanize(row) }
    end
  end

  private


  def self.humanize(row)
    addr = row["address"] || {}
    {
        name:  addr["city"]    || addr["town"]   || addr["village"] || addr["hamlet"] || row["display_name"].split(",").first,
        state: addr["state"]   || addr["region"] || "",
        lat:   row["lat"].to_f,
        lon:   row["lon"].to_f
    }
  end
end

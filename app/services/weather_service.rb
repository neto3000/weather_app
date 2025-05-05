class WeatherService
  CACHE_TIME  = 1.hour

  def initialize(provider, params = {})
    @provider = provider
    @api_key = Rails.application.credentials[Rails.env.to_sym][@provider.name.to_sym][:api_key]
    @lat = params[:lat]
    @lon = params[:lon]
    @city = params[:city]
    @state = params[:state]
    @country = params[:country]
    @zip_code = params[:zip_code]
  end

  def fetch
    @city, @state, @country = convert_cord_to_city if @city.blank?
    query = { city: @city }
    query.merge!(state: @state) if @state.present?
    query.merge!(country: @country) if @country.present?

    cached = WeatherReading.where(provider_id: @provider.id).where(query).first

    if cached.present?
      if cached.fetched_at > CACHE_TIME.ago
        cached
      else
        update_expired_weather_reading(cached)
      end
    else
      create_weather_reading
    end
  end

  private

  def update_expired_weather_reading(expired_weather_reading)
    response = fetch_weather

    expired_weather_reading.update!(lat: @lat, lon: @lon, payload: response.body, fetched_at: Time.current )
  end

  def create_weather_reading
    @lat, @lon = convert_city_to_cord if @city.present? && (@lat.nil? && @lon.nil?)
    response = fetch_weather

    WeatherReading.create!(
        provider:   @provider,
        lat:        @lat,
        lon:        @lon,
        city:       @city,
        state:      @state,
        country:    @country,
        zip_code:   @zip_code,
        payload:    response.body,

        fetched_at: Time.current
    )
  end

  # TODO: A more elegant design would be to create a client for each weather provider, leaving this at the end of time's sake
  def fetch_weather
    base_url = "https://api.openweathermap.org/data/3.0/onecall?lat=#{@lat}&lon=#{@lon}&appid=#{@api_key}"
    Faraday.get(base_url)
  end

  def convert_city_to_cord
    base_url_convert = "http://api.openweathermap.org/geo/1.0/direct?q=#{@city},#{@state},#{@country}&limit=#{1}&appid=#{@api_key}"

    response = Faraday.get(base_url_convert)
    parsed_response = JSON.parse(response.body).first

    [ parsed_response['lat'], parsed_response['lon'] ]
  end

  def convert_cord_to_city
    base_url_convert = "http://api.openweathermap.org/geo/1.0/reverse?lat=#{@lat}&lon=#{@lon}&limit=#{1}&appid=#{@api_key}"

    response = Faraday.get(base_url_convert)
    parsed_response = JSON.parse(response.body).first

    [ parsed_response['name'], parsed_response['state'], parsed_response['country'] ]
  end
end

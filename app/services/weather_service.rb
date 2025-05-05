class WeatherService
  CACHE_TIME  = 1.hour

  def initialize(provider)
    @provider = provider
    @api_key = Rails.application.credentials[Rails.env.to_sym][@provider.name.to_sym][:api_key]
  end

  def fetch(params)
    # TODO: Implement cache

    fetch_weather(params)
  end

  private

  def fetch_weather(params)
    @lat = params[:lat]
    @lon = params[:lon]
    @city = params[:city]
    @state = params[:state]
    @country = params[:country]
    @zip_code = params[:zip_code]
    @lat, @lon = convert_city_to_cord if params[:city].present?

    base_url = "https://api.openweathermap.org/data/3.0/onecall?lat=#{@lat}&lon=#{@lon}&appid=#{@api_key}"
    response = Faraday.get(base_url)

    @city, @state, @country = convert_cord_to_city if params[:city].blank?

    save_update_weather_reading(response)
  end


  def save_update_weather_reading(response)
    WeatherReading.create!(
        provider:   @provider,
        lat:        @lat,
        lon:        @lon,
        city:       @city ,
        state:      @state,
        country:    @country,
        zip_code:   @zip_code,
        payload:    response.body,

        fetched_at: Time.current
    )
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






# spec/services/weather_service_spec.rb
require "rails_helper"
require "webmock/rspec"

RSpec.describe WeatherService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:provider) { Provider.create!(name: "OpenWeatherMap") }
  let(:base)     { "https://api.openweathermap.org" }

  def stub_openweather(lat: 20.97, lon: -89.62)
    # main weather
    stub_request(:get, %r{api\.openweathermap\.org/data/3\.0/onecall})
        .to_return(body: { ok: true }.to_json)

    # city → coords
    stub_request(:get, %r{api\.openweathermap\.org/geo/1\.0/direct})
        .to_return(body: [{
                              lat: lat, lon: lon, name: "Merida", state: "Yucatán", country: "MX"
                          }].to_json)

    # coords → city
    stub_request(:get, %r{api\.openweathermap\.org/geo/1\.0/reverse})
        .to_return(body: [{
                              name: "Merida", state: "Yucatán", country: "MX"
                          }].to_json)
  end


  before  { travel_to(Time.zone.parse("2025-05-05 12:00"))  }
  after   { travel_back }


  context "first fetch when nothing cached" do
    it "creates a new WeatherReading" do
      stub_openweather

      service = WeatherService.new(provider, city: "Merida", country: "MX")

      expect { @reading = service.fetch }
          .to change(WeatherReading, :count).by(1)

      expect(@reading.city).to   eq("Merida")
      expect(@reading.payload).to include("ok")
      expect(@reading.fetched_at).to be_within(1.second).of(Time.current)
    end
  end

  context "cached and still fresh" do
    it "returns the cached reading and makes no API calls" do
      reading = WeatherReading.create!(
          provider: provider,
          city: "Merida", country: "MX",
          payload: "cached", fetched_at: Time.current
      )

      service = WeatherService.new(provider, city: "Merida", country: "MX")

      expect(service.fetch).to eq(reading)
      expect(a_request(:get, /onecall/)).not_to have_been_made
    end
  end

  context "cached but expired" do
    it "updates the existing record in place" do
      stub_openweather
      expired = WeatherReading.create!(
          provider: provider,
          city: "Merida", country: "MX",
          payload: "old",
          fetched_at: 2.hours.ago
      )

      refreshed = WeatherService.new(
          provider,
          city: "Merida", country: "MX"
      ).fetch

      expect(refreshed.id).to eq(expired.id)
      expect(refreshed.payload).to include("ok")
      expect(refreshed.fetched_at)
          .to be_within(1.second).of(Time.current)
    end
  end
end

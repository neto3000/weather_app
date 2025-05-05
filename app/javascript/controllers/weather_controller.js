
const kelvinToF = k => Math.round((k - 273.15) * 9 / 5 + 32);
const toLocalTime = unix =>
  new Date(unix * 1000).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });


import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["providerSelect", "cityForm", "city", "state"]

  connect() {
    this.providers = JSON.parse(this.element.dataset.weatherProviders)
    this.buildProviderDropdown()
    this.getWithGeolocation()
  }

  buildProviderDropdown() {
    this.providers.forEach(p => {
      const opt = document.createElement("option")
      opt.value = p.id
      opt.textContent = p.name
      this.providerSelectTarget.appendChild(opt)
    })
  }

  getWithGeolocation() {
    if (!navigator.geolocation) return
    navigator.geolocation.getCurrentPosition(pos => {
      this.fetchAndRender({ lat: pos.coords.latitude, lon: pos.coords.longitude })
    })
  }

  citySearch(event) {
    event.preventDefault()
    this.fetchAndRender({ city: this.cityTarget.value, state: this.stateTarget.value })
  }

  fetchAndRender(params) {
    params.provider_id = this.providerSelectTarget.value
    fetch(`/weather/search?${new URLSearchParams(params)}`)
      .then(r => r.json())
      .then(json => this.renderCard(json))
  }

  renderCard(data) {
    const current_weather = data.current

    // Normalise / convert values
    const iconUrl    = `https://openweathermap.org/img/wn/${current_weather.weather[0].icon}@2x.png`
    const tempF      = kelvinToF(current_weather.temp)
    const feelsF     = kelvinToF(current_weather.feels_like)
    const humidity   = `${current_weather.humidity}%`
    const windMph    = `${Math.round(current_weather.wind_speed * 2.23694)} mph`
    const pressure   = `${current_weather.pressure} hPa`
    const visibility = `${(current_weather.visibility / 1609.34).toFixed(1)} mi`
    const sunrise    = toLocalTime(current_weather.sunrise)
    const sunset     = toLocalTime(current_weather.sunset)

    document.querySelector("#weather-card").innerHTML = `
      <div class="max-w-md mx-auto bg-white border rounded-2xl shadow p-6">
        <!-- Header -->
        <div class="flex items-center gap-4 mb-6">
          <img src="${iconUrl}" alt="${current_weather.weather[0].description}" class="h-16 w-16">
          <div>
            <div class="flex items-start leading-none">
              <span class="text-5xl font-bold">${tempF}</span>
              <span class="text-2xl mt-1">°F</span>
            </div>
            <p class="capitalize text-gray-500">${current_weather.weather[0].description}</p>
          </div>
        </div>

        <!-- Stats grid -->
        <div class="grid grid-cols-2 gap-x-6 gap-y-4 text-sm text-gray-700">
          <div class="flex justify-between"><span>Feels like</span><span class="font-medium">${feelsF}°F</span></div>
          <div class="flex justify-between"><span>Humidity</span><span class="font-medium">${humidity}</span></div>
          <div class="flex justify-between"><span>Wind</span><span class="font-medium">${windMph}</span></div>
          <div class="flex justify-between"><span>Pressure</span><span class="font-medium">${pressure}</span></div>
          <div class="flex justify-between"><span>Visibility</span><span class="font-medium">${visibility}</span></div>
          <div class="flex justify-between"><span>Clouds</span><span class="font-medium">${current_weather.clouds}%</span></div>
        </div>

        <!-- Sunrise / Sunset -->
        <div class="mt-6 pt-4 border-t text-xs text-gray-500 grid grid-cols-2 gap-4">
          <div>🌅 Sunrise&nbsp;<span class="font-semibold">${sunrise}</span></div>
          <div>🌇 Sunset&nbsp;<span class="font-semibold">${sunset}</span></div>
        </div>
      </div>
    `
  }
}

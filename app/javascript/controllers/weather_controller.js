
const kelvinToF = k => Math.round((k - 273.15) * 9 / 5 + 32);
const toLocalTime = unix =>
  new Date(unix * 1000).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

const debounce = (fn, delay = 300) => {
  let t
  return function (...args) {
    clearTimeout(t)
    const context = this
    t = setTimeout(() => fn.apply(context, args), delay)
  }
}

const dayName = unix =>
  new Date(unix * 1000).toLocaleDateString([], { weekday: "short" }) // "Mon"

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "providerSelect",
    "search", "suggestions",
  ]

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
      .then(json => {
        this.renderCard(json)          // existing main card
        this.renderForecast(json.daily.slice(0, 8)) // show next 8 days
      })
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
    const locationLine = `${data.city}, ${data.state}, ${data.country}`


    document.querySelector("#weather-card").innerHTML = `
  <div class="bg-white/80 dark:bg-gray-800/70
              border border-gray-200 dark:border-gray-700
              rounded-xl shadow p-6
              text-gray-900 dark:text-gray-100">  <!-- ← base text colour -->

    <h2 class="text-lg font-semibold mb-3 text-center">${locationLine}</h2>
    <!-- Header -->
    <div class="flex items-center gap-4 mb-6">
      <img src="${iconUrl}" alt="${current_weather.weather[0].description}" class="h-16 w-16">
      <div>
        <div class="flex items-start leading-none">
          <span class="text-5xl font-bold">${tempF}</span>
          <span class="text-2xl mt-1">°F</span>
        </div>
        <p class="capitalize text-gray-500 dark:text-gray-400">
          ${current_weather.weather[0].description}
        </p>   <!-- secondary text: lighter in both themes -->
      </div>
    </div>

    <!-- Stats grid -->
    <div class="grid grid-cols-2 gap-x-6 gap-y-4 text-sm">
      <!-- primary numbers inherit bright text-gray-100 in dark mode -->
      <div class="flex justify-between">
        <span>Feels like</span><span class="font-medium">${feelsF}°F</span>
      </div>
      <div class="flex justify-between">
        <span>Humidity</span><span class="font-medium">${humidity}</span>
      </div>
      <div class="flex justify-between">
        <span>Wind</span><span class="font-medium">${windMph}</span>
      </div>
      <div class="flex justify-between">
        <span>Pressure</span><span class="font-medium">${pressure}</span>
      </div>
      <div class="flex justify-between">
        <span>Visibility</span><span class="font-medium">${visibility}</span>
      </div>
      <div class="flex justify-between">
        <span>Clouds</span><span class="font-medium">${current_weather.clouds}%</span>
      </div>
    </div>

    <!-- Sunrise / Sunset -->
    <div class="mt-6 pt-4 border-t text-xs text-gray-600 dark:text-gray-400
                grid grid-cols-2 gap-4">
      <div>🌅 Sunrise&nbsp;<span class="font-semibold">${sunrise}</span></div>
      <div>🌇 Sunset&nbsp;<span class="font-semibold">${sunset}</span></div>
    </div>
  </div>
`
  }

  // --- autocomplete: on-type
  type = debounce(async function () {
    const q = this.searchTarget.value.trim()
    if (q.length < 2) { this.hideSuggestions(); return }

    const res  = await fetch(`/cities/search?q=${encodeURIComponent(q)}`)
    const list = await res.json()          // [{ name, state, lat, lon }, …]

    if (list.length === 0) { this.hideSuggestions(); return }

    this.suggestionsTarget.innerHTML = list.map(city => `
    <li class="px-4 py-2 hover:bg-indigo-50 cursor-pointer"
        data-action="click->weather#pick"
        data-city='${JSON.stringify(city)}'>
      ${city.name}, ${city.state}
    </li>
  `).join("")
    this.suggestionsTarget.classList.remove("hidden")
  })

// --- autocomplete: on-pick
  pick(event) {
    const city = JSON.parse(event.currentTarget.dataset.city)
    this.searchTarget.value = `${city.name}, ${city.state}`
    this.hideSuggestions()
    this.fetchAndRender({ lat: city.lat, lon: city.lon })
  }

// --- helper
  hideSuggestions() { this.suggestionsTarget.classList.add("hidden") }

  renderForecast(days) {
    if (!Array.isArray(days) || days.length === 0) return

    const cards = days.map((d, idx) => {
      const max = kelvinToF(d.temp.max)
      const min = kelvinToF(d.temp.min)
      const icon = `https://openweathermap.org/img/wn/${d.weather[0].icon}.png`
      const label = dayName(d.dt)

      return `
      <div class="flex flex-col items-center gap-1 py-4
                  bg-white/80 dark:bg-gray-800/70
                  rounded-xl shadow text-xs w-16 shrink-0">
        <span class="font-medium text-gray-700 dark:text-gray-200">${label}</span>
        <img src="${icon}" alt="${d.weather[0].description}" class="h-8 w-8">
        <span class="text-gray-900 dark:text-gray-100 font-semibold">${max}°</span>
        <span class="text-gray-500 dark:text-gray-400">${min}°</span>
      </div>
    `
    }).join("")

    document.querySelector("#forecast-strip").innerHTML = `
    <div class="flex gap-2 overflow-x-auto px-2">${cards}</div>
  `
  }
}

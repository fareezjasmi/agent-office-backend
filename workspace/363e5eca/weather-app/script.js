'use strict';

/* =========================================================
   Weather code -> { description, icon } lookup
========================================================= */
const WEATHER_CODES = {
  0: { description: 'Clear sky', icon: '☀️' },
  1: { description: 'Mainly clear', icon: '🌤️' },
  2: { description: 'Partly cloudy', icon: '⛅' },
  3: { description: 'Overcast', icon: '☁️' },
  45: { description: 'Fog', icon: '🌫️' },
  48: { description: 'Depositing rime fog', icon: '🌫️' },
  51: { description: 'Light drizzle', icon: '🌦️' },
  53: { description: 'Moderate drizzle', icon: '🌦️' },
  55: { description: 'Dense drizzle', icon: '🌧️' },
  56: { description: 'Light freezing drizzle', icon: '🌧️' },
  57: { description: 'Dense freezing drizzle', icon: '🌧️' },
  61: { description: 'Slight rain', icon: '🌧️' },
  63: { description: 'Moderate rain', icon: '🌧️' },
  65: { description: 'Heavy rain', icon: '🌧️' },
  66: { description: 'Light freezing rain', icon: '🌧️' },
  67: { description: 'Heavy freezing rain', icon: '🌧️' },
  71: { description: 'Slight snow fall', icon: '🌨️' },
  73: { description: 'Moderate snow fall', icon: '🌨️' },
  75: { description: 'Heavy snow fall', icon: '❄️' },
  77: { description: 'Snow grains', icon: '❄️' },
  80: { description: 'Slight rain showers', icon: '🌦️' },
  81: { description: 'Moderate rain showers', icon: '🌧️' },
  82: { description: 'Violent rain showers', icon: '⛈️' },
  85: { description: 'Slight snow showers', icon: '🌨️' },
  86: { description: 'Heavy snow showers', icon: '❄️' },
  95: { description: 'Thunderstorm', icon: '⛈️' },
  96: { description: 'Thunderstorm with slight hail', icon: '⛈️' },
  99: { description: 'Thunderstorm with heavy hail', icon: '⛈️' },
};

const DEFAULT_WEATHER = { description: 'Unknown conditions', icon: '❓' };

function getWeatherInfo(code) {
  return WEATHER_CODES[code] || DEFAULT_WEATHER;
}

/* =========================================================
   DOM references
========================================================= */
const searchForm = document.getElementById('searchForm');
const cityInput = document.getElementById('cityInput');
const geoBtn = document.getElementById('geoBtn');
const unitToggle = document.getElementById('unitToggle');

const loadingEl = document.getElementById('loading');
const errorEl = document.getElementById('errorMessage');
const welcomeEl = document.getElementById('welcomeMessage');
const weatherContentEl = document.getElementById('weatherContent');

const locationNameEl = document.getElementById('locationName');
const dayNightEl = document.getElementById('dayNight');
const currentIconEl = document.getElementById('currentIcon');
const currentDescriptionEl = document.getElementById('currentDescription');
const currentTempEl = document.getElementById('currentTemp');
const feelsLikeEl = document.getElementById('feelsLike');
const humidityEl = document.getElementById('humidity');
const windSpeedEl = document.getElementById('windSpeed');
const forecastGridEl = document.getElementById('forecastGrid');

/* =========================================================
   App state
========================================================= */
// Cached last-fetched data so the unit toggle can re-render
// without another network call.
let lastData = null; // { locationLabel, current: {...}, daily: {...} }
let currentUnit = 'C'; // 'C' or 'F'

/* =========================================================
   UI helpers
========================================================= */
function showLoading() {
  loadingEl.classList.remove('hidden');
  hideError();
}

function hideLoading() {
  loadingEl.classList.add('hidden');
}

function showError(message) {
  errorEl.textContent = message;
  errorEl.classList.remove('hidden');
  welcomeEl.classList.add('hidden');
}

function hideError() {
  errorEl.classList.add('hidden');
  errorEl.textContent = '';
}

function showWelcome() {
  welcomeEl.classList.remove('hidden');
  weatherContentEl.classList.add('hidden');
}

function showWeatherContent() {
  welcomeEl.classList.add('hidden');
  weatherContentEl.classList.remove('hidden');
}

/* =========================================================
   Unit conversion
========================================================= */
function celsiusToFahrenheit(celsius) {
  return (celsius * 9) / 5 + 32;
}

function formatTemp(celsiusValue) {
  if (celsiusValue === null || celsiusValue === undefined || Number.isNaN(celsiusValue)) {
    return '--°';
  }
  const value = currentUnit === 'F' ? celsiusToFahrenheit(celsiusValue) : celsiusValue;
  return `${Math.round(value)}°${currentUnit}`;
}

/* =========================================================
   Fetch helpers
========================================================= */
async function geocodeCity(cityName) {
  const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(
    cityName
  )}&count=5&language=en&format=json`;

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error('NETWORK_ERROR');
  }
  const data = await response.json();
  if (!data.results || data.results.length === 0) {
    throw new Error('CITY_NOT_FOUND');
  }
  return data.results[0];
}

async function fetchForecast(latitude, longitude) {
  const url =
    `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}` +
    `&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day` +
    `&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max` +
    `&timezone=auto&forecast_days=7`;

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error('NETWORK_ERROR');
  }
  const data = await response.json();
  if (!data.current || !data.daily) {
    throw new Error('NETWORK_ERROR');
  }
  return data;
}

async function reverseGeocode(latitude, longitude) {
  try {
    const url = `https://geocoding-api.open-meteo.com/v1/reverse?latitude=${latitude}&longitude=${longitude}&language=en&format=json`;
    const response = await fetch(url);
    if (!response.ok) return null;
    const data = await response.json();
    if (data.results && data.results.length > 0) {
      return data.results[0];
    }
    return null;
  } catch (err) {
    // best-effort only; never let this break the main flow
    return null;
  }
}

/* =========================================================
   Rendering
========================================================= */
function buildLocationLabel(place) {
  if (!place) return 'Your Location';
  const parts = [place.name];
  if (place.admin1 && place.admin1 !== place.name) parts.push(place.admin1);
  if (place.country) parts.push(place.country);
  return parts.join(', ');
}

function renderCurrentWeather() {
  if (!lastData) return;
  const { locationLabel, current } = lastData;
  const weatherInfo = getWeatherInfo(current.weather_code);

  locationNameEl.textContent = locationLabel;
  dayNightEl.textContent = current.is_day === 0 ? '🌙 Night' : '☀️ Day';

  currentIconEl.textContent = weatherInfo.icon;
  currentDescriptionEl.textContent = weatherInfo.description;

  currentTempEl.textContent = formatTemp(current.temperature_2m);
  feelsLikeEl.textContent = `Feels like ${formatTemp(current.apparent_temperature)}`;

  humidityEl.textContent = `${Math.round(current.relative_humidity_2m)}%`;
  windSpeedEl.textContent = `${Math.round(current.wind_speed_10m)} km/h`;
}

function formatWeekday(dateString) {
  const date = new Date(`${dateString}T00:00:00`);
  return date.toLocaleDateString(undefined, { weekday: 'short' });
}

function renderForecast() {
  if (!lastData) return;
  const { daily } = lastData;

  forecastGridEl.innerHTML = '';

  for (let i = 0; i < daily.time.length; i++) {
    const weatherInfo = getWeatherInfo(daily.weather_code[i]);
    const card = document.createElement('div');
    card.className = 'forecast-card';

    card.innerHTML = `
      <div class="forecast-day">${formatWeekday(daily.time[i])}</div>
      <div class="forecast-icon">${weatherInfo.icon}</div>
      <div class="forecast-desc">${weatherInfo.description}</div>
      <div class="forecast-temps">
        <span class="forecast-high">${formatTemp(daily.temperature_2m_max[i])}</span>
        <span class="forecast-low">${formatTemp(daily.temperature_2m_min[i])}</span>
      </div>
      <div class="forecast-precip">💧 ${Math.round(daily.precipitation_probability_max[i] ?? 0)}%</div>
    `;

    forecastGridEl.appendChild(card);
  }
}

function renderAll() {
  renderCurrentWeather();
  renderForecast();
  showWeatherContent();
}

/* =========================================================
   Main flows
========================================================= */
async function loadWeatherForCity(cityName) {
  showLoading();
  try {
    const place = await geocodeCity(cityName);
    const forecast = await fetchForecast(place.latitude, place.longitude);

    lastData = {
      locationLabel: buildLocationLabel(place),
      current: forecast.current,
      daily: forecast.daily,
    };

    renderAll();
    hideError();
  } catch (err) {
    handleFetchError(err);
  } finally {
    hideLoading();
  }
}

async function loadWeatherForCoords(latitude, longitude) {
  showLoading();
  try {
    const forecast = await fetchForecast(latitude, longitude);
    const place = await reverseGeocode(latitude, longitude);

    lastData = {
      locationLabel: place ? buildLocationLabel(place) : 'Your Location',
      current: forecast.current,
      daily: forecast.daily,
    };

    renderAll();
    hideError();
  } catch (err) {
    handleFetchError(err);
  } finally {
    hideLoading();
  }
}

function handleFetchError(err) {
  if (err && err.message === 'CITY_NOT_FOUND') {
    showError('City not found. Please check the spelling and try again.');
  } else if (err && err.message === 'NETWORK_ERROR') {
    showError('Could not reach the weather service. Please check your connection and try again.');
  } else {
    showError('Something went wrong while fetching the weather. Please try again.');
  }
}

/* =========================================================
   Event listeners
========================================================= */
searchForm.addEventListener('submit', (event) => {
  event.preventDefault();
  const cityName = cityInput.value.trim();
  if (!cityName) {
    showError('Please enter a city name.');
    return;
  }
  loadWeatherForCity(cityName);
});

// Enter key is already handled by the form submit event above since the
// input lives inside a <form>, but we add an explicit keypress listener
// too, to be robust regardless of markup structure.
cityInput.addEventListener('keypress', (event) => {
  if (event.key === 'Enter') {
    event.preventDefault();
    const cityName = cityInput.value.trim();
    if (!cityName) {
      showError('Please enter a city name.');
      return;
    }
    loadWeatherForCity(cityName);
  }
});

geoBtn.addEventListener('click', () => {
  if (!('geolocation' in navigator)) {
    showError('Geolocation is not supported by your browser.');
    return;
  }

  showLoading();
  navigator.geolocation.getCurrentPosition(
    (position) => {
      const { latitude, longitude } = position.coords;
      loadWeatherForCoords(latitude, longitude);
    },
    (error) => {
      hideLoading();
      if (error.code === error.PERMISSION_DENIED) {
        showError('Location permission was denied. Please allow location access or search for a city instead.');
      } else {
        showError('Unable to retrieve your location. Please try again or search for a city instead.');
      }
    }
  );
});

unitToggle.addEventListener('click', () => {
  currentUnit = currentUnit === 'C' ? 'F' : 'C';
  unitToggle.textContent = currentUnit === 'C' ? 'Switch to °F' : 'Switch to °C';
  unitToggle.setAttribute('aria-pressed', currentUnit === 'F' ? 'true' : 'false');

  // Re-render from cached data only -- no new API call.
  if (lastData) {
    renderAll();
  }
});

/* =========================================================
   Initial state
========================================================= */
showWelcome();

---
name: weather-forecast
description: Fetch and display weather forecast from Open-Meteo API
usage: weather-forecast <city> <country> [days_ahead]
parameters:
  - name: city
    description: City name
    required: true
  - name: country
    description: Country name
    required: true
  - name: days_ahead
    description: Number of days to forecast (default 7)
    required: false
    default: "7"
examples:
  - weather-forecast Brandal Norway
  - weather-forecast Oslo Norway 5
  - weather-forecast London "United Kingdom" 3
---

Fetch weather forecast for a location using Open-Meteo API.

Displays current weather conditions and n-day forecast in a table format:
- Temperature (high/low)
- Weather condition
- Precipitation amount

Uses curl to query Open-Meteo API endpoints:
- Geocoding: Find location coordinates
- Forecast: Get weather data for the coordinates

Output format shows current conditions followed by a markdown table with daily forecasts.

#!/bin/bash

set -e

# Parse arguments
city="${1:?City required}"
country="${2:?Country required}"
days_ahead="${3:-7}"

# Validate days_ahead is a number
if ! [[ "$days_ahead" =~ ^[0-9]+$ ]]; then
  echo "Error: days_ahead must be a number"
  exit 1
fi

# Open-Meteo serves at most 16 daily forecast days
if (( days_ahead < 1 )); then
  days_ahead=1
elif (( days_ahead > 16 )); then
  days_ahead=16
fi

# Weather code to description
get_weather_condition() {
  local code=$1
  case "$code" in
    0) echo "Clear" ;;
    1) echo "Mostly clear" ;;
    2) echo "Partly cloudy" ;;
    3) echo "Overcast" ;;
    45|48) echo "Foggy" ;;
    51) echo "Light drizzle" ;;
    53) echo "Drizzle" ;;
    55) echo "Heavy drizzle" ;;
    61) echo "Rain" ;;
    63) echo "Heavy rain" ;;
    65) echo "Violent rain" ;;
    71) echo "Light snow" ;;
    73) echo "Snow" ;;
    75) echo "Heavy snow" ;;
    77) echo "Snow grains" ;;
    80) echo "Showers" ;;
    81) echo "Heavy showers" ;;
    82) echo "Violent showers" ;;
    85) echo "Snow showers" ;;
    86) echo "Heavy snow showers" ;;
    95) echo "Thunderstorm" ;;
    96|99) echo "Thunderstorm with hail" ;;
    *) echo "Unknown" ;;
  esac
}

# Geocode city/country
geo_data=$(curl -s "https://geocoding-api.open-meteo.com/v1/search?name=$(echo -n "$city" | jq -sRr @uri)&country=$(echo -n "$country" | jq -sRr @uri)&limit=10")

# Filter results by country to get the right location
lat=$(echo "$geo_data" | jq -r ".results[] | select(.country == \"$country\") | .latitude" | head -1)
lon=$(echo "$geo_data" | jq -r ".results[] | select(.country == \"$country\") | .longitude" | head -1)

if [[ -z "$lat" || "$lat" == "null" ]]; then
  echo "Error: Could not find location '$city, $country'"
  exit 1
fi

# Fetch forecast
forecast=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&forecast_days=${days_ahead}&timezone=auto")

# Parse current weather
current_temp=$(echo "$forecast" | jq -r '.current.temperature_2m')
current_code=$(echo "$forecast" | jq -r '.current.weather_code')
current_humidity=$(echo "$forecast" | jq -r '.current.relative_humidity_2m')
current_wind=$(echo "$forecast" | jq -r '.current.wind_speed_10m')
current_condition=$(get_weather_condition "$current_code")

# Display current weather
echo "**Current ($city):**"
echo "- Temp: ${current_temp}°C"
echo "- Condition: $current_condition"
echo "- Humidity: ${current_humidity}%"
echo "- Wind: ${current_wind} km/h"
echo ""

# Display forecast table header
echo "**${days_ahead}-day forecast:**"
echo "| Day | High | Low | Condition | Rain |"
echo "|-----|------|-----|-----------|------|"

# Extract and display daily forecasts
for i in $(seq 0 $((days_ahead - 1))); do
  date=$(echo "$forecast" | jq -r ".daily.time[$i]")
  temp_max=$(echo "$forecast" | jq -r ".daily.temperature_2m_max[$i]")
  temp_min=$(echo "$forecast" | jq -r ".daily.temperature_2m_min[$i]")
  precip=$(echo "$forecast" | jq -r ".daily.precipitation_sum[$i]")
  code=$(echo "$forecast" | jq -r ".daily.weather_code[$i]")
  condition=$(get_weather_condition "$code")

  # Format date
  date_display=$(date -j -f "%Y-%m-%d" "$date" "+%b %d" 2>/dev/null || echo "$date")

  # Format precipitation (show only if > 0)
  if (( $(echo "$precip > 0" | bc -l) )); then
    rain_display="${precip}mm"
  else
    rain_display="—"
  fi

  echo "| $date_display | ${temp_max}°C | ${temp_min}°C | $condition | $rain_display |"
done

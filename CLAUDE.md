# Project guidance

## Weather requests

Whenever the user asks for the weather, temperature, or forecast for a place,
delegate to the `weather-forecaster` subagent (via the Agent tool) — do NOT run
the weather-forecast skill yourself in the main thread.

- **Single place:** spin up one `weather-forecaster` agent for that location and
  relay its result.
- **Comparing multiple places:** spin up one `weather-forecaster` agent PER place
  IN PARALLEL — issue all the Agent calls in a single message so they run
  concurrently. Once every agent returns, compare the results yourself in the
  main thread and present the comparison.

The subagent runs `.claude/skills/weather-forecast/scripts/run.sh <city>
<country> [days_ahead]` (Open-Meteo via curl). Pass the city, country, and days
ahead through to it.

# weather-forecaster-agent

A small [Claude Code](https://claude.com/claude-code) setup that fetches weather
forecasts from the free [Open-Meteo](https://open-meteo.com/) API. It ships two
pieces that work together — a **skill** that does the actual fetching and a
**subagent** that wraps it — plus project guidance that tells the main agent to
delegate every weather request to the subagent.

## Components

### `weather-forecast` skill
`.claude/skills/weather-forecast/`

Fetches and formats the forecast for one location. Backed by a bash script
(`scripts/run.sh`) that:

1. Geocodes `<city> <country>` via the Open-Meteo geocoding API to get
   coordinates.
2. Fetches current conditions and the daily forecast for those coordinates.
3. Prints a **Current** block (temp, condition, humidity, wind) followed by an
   n-day markdown table (Day | High | Low | Condition | Rain).

Weather codes are mapped to human-readable conditions (Clear, Overcast, Rain,
Thunderstorm, …), and precipitation is shown only when it's greater than zero.

**Usage:**

```
.claude/skills/weather-forecast/scripts/run.sh <city> <country> [days_ahead]
```

| Argument | Required | Default | Notes |
|----------|----------|---------|-------|
| `city` | yes | — | City name |
| `country` | yes | — | Country name (used to disambiguate results) |
| `days_ahead` | no | `7` | Number of days to forecast |

**Examples:**

```
.claude/skills/weather-forecast/scripts/run.sh Brandal Norway
.claude/skills/weather-forecast/scripts/run.sh Oslo Norway 5
.claude/skills/weather-forecast/scripts/run.sh London "United Kingdom" 3
```

Quote multi-word city or country names.

### `weather-forecaster` subagent
`.claude/agents/weather-forecaster.md`

A single-purpose subagent (model: `haiku`, tools: `Bash`, `Skill`) whose only
job is to fetch and report the forecast for **one** location by running the
skill's script and returning its output verbatim. It never compares locations —
that's left to the main agent.

### Project guidance
`CLAUDE.md`

Instructs the main agent to delegate weather requests to the subagent:

- **Single place:** spin up one `weather-forecaster` agent and relay its result.
- **Comparing places:** spin up one `weather-forecaster` per place **in
  parallel** (all Agent calls in one message), then compare the results in the
  main thread.

This keeps each fetch isolated and lets multi-city comparisons run concurrently.

## Requirements

The script relies on standard command-line tools:

- `curl` — API requests
- `jq` — JSON parsing and URL-encoding
- `bc` — precipitation comparison
- BSD `date` (macOS) for date formatting (falls back to the raw ISO date
  elsewhere)

No API key is needed — Open-Meteo is free for non-commercial use.

## Layout

```
.
├── CLAUDE.md                                   # project guidance / delegation rules
└── .claude/
    ├── agents/
    │   └── weather-forecaster.md               # subagent definition
    └── skills/
        └── weather-forecast/
            ├── SKILL.md                        # skill definition
            └── scripts/
                └── run.sh                      # Open-Meteo fetch + format
```

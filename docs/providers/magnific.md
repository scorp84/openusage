# Magnific

Magnific tracks your team credit usage over the last 30 days.

## Credentials

The user provides their API key via **Settings ▸ API Keys**. It is stored in `~/.config/openusage/magnific.json` or can be supplied via the `MAGNIFIC_API_KEY` environment variable.

## API Endpoints

- **POST `https://api.magnific.com/v1/analytics/team-credit-usage`** — Fetches credit consumption data for the past 30 days.

## Error States

- **No Magnific API key** — No key found in the environment or config file.
- **Magnific API key invalid** — HTTP 401/403 returned, meaning the key is revoked, expired, or invalid.
- **Magnific usage data unavailable** — The endpoint returned an undecodable response or an HTTP 5xx error.

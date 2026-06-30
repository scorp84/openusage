# Fal.ai

Fal.ai tracks API billing balance.

## Credentials

The user provides their API key via **Settings ▸ API Keys**. It is stored in `~/.config/openusage/fal.json` or can be supplied via the `FAL_API_KEY` environment variable.

## API Endpoints

- **GET `https://api.fal.ai/v1/account/billing`** — Fetches the account balance.

## Error States

- **No Fal.ai API key** — No key found in the environment or config file.
- **Fal.ai API key invalid** — HTTP 401/403 returned, meaning the key is revoked, expired, or invalid.
- **Fal.ai usage data unavailable** — The endpoint returned an undecodable response or an HTTP 5xx error.

# Higgsfield

Higgsfield tracks your account credit balance.

## Credentials

The user provides their API key via **Settings ▸ API Keys**. It is stored in `~/.config/openusage/higgsfield.json` or can be supplied via the `HIGGSFIELD_API_KEY` environment variable.

## API Endpoints

- **GET `https://cloud.higgsfield.ai/api/v1/account/balance`** — Fetches the account balance.

## Error States

- **No Higgsfield.ai API key** — No key found in the environment or config file.
- **Higgsfield.ai API key invalid** — HTTP 401/403 returned, meaning the key is revoked, expired, or invalid.
- **Higgsfield.ai usage data unavailable** — The endpoint returned an undecodable response or an HTTP 5xx error.

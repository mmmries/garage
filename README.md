# Garage

A Garage-door opener project

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/supported-targets.html

## Getting Started

Create a `.env` file with all the secrets you need

```
export NERVES_SSID="MySSID"
export NERVES_PSK="WifiPassword"
export MIX_TARGET="rpi3a"
export NATS_JWT="...get your JWT from the synadia cloud site..."
export NATS_NKEY_SEED="...get from the synadia cloud site..."
export NERVES_CLOUD_KEY="...get from nerves cloud site..."
export NERVES_CLOUD_SECRET="...get from nerves cloud site..."
```

  * Now load secrets with `source .env`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix burn` or update the device with `./upload.sh garage.local`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Elixir Slack #nerves channel: https://elixir-slack.community/
  * Elixir Discord #nerves channel: https://discord.gg/elixir
  * Source: https://github.com/nerves-project/nerves

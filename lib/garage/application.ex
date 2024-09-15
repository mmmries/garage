defmodule Garage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Garage.Supervisor]

    children =
      [
        # Children that should run on all devices
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Garage.Worker.start_link(arg)
      # {Garage.Worker, arg},
    ]
  end

  def children(_target) do
    [
      Garage.Button,
      {Gnat.ConnectionSupervisor, connection_settings()},
      {Gnat.ConsumerSupervisor, supervisor_settings()},
      Garage.DoorMonitor
    ]
  end

  def target() do
    Application.get_env(:garage, :target)
  end

  defp connection_settings do
    %{
      name: :gnat,
      backoff_period: 5_000,
      connection_settings: [
        Application.get_env(:garage, :nats_conn_settings)
      ]
    }
  end

  defp supervisor_settings do
    %{
      connection_name: :gnat,
      module: Garage.NatsServer,
      subscription_topics: [
        %{topic: "home.garage_door"}
      ]
    }
  end
end

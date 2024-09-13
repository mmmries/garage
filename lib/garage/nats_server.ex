defmodule Garage.NatsServer do
  use Gnat.Server
  require Logger

  def request(%{body: "toggle", topic: "home.garage_door"}) do
    Garage.Button.toggle_door()
    :ok
  end

  def request(other) do
    Logger.error("Unexpected Nats Message", message: other)
    :ok
  end
end

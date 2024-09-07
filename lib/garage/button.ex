defmodule Garage.Button do
  use GenServer
  alias Circuits.GPIO

  @relay_pin 22

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, gpio} = GPIO.open(@relay_pin, :output)
    {:ok, %{gpio: gpio}}
  end

  def toggle_door do
    GenServer.cast(__MODULE__, :toggle)
  end

  def handle_cast(:toggle, state) do
    GPIO.write(state.gpio, 1)
    # Hold the "button press" for 500ms
    Process.sleep(500)
    GPIO.write(state.gpio, 0)
    {:noreply, state}
  end
end

defmodule Garage.ScreenMonitor do
  use GenServer
  require Logger
  alias Circuits.GPIO

  @screen_pin 27
  @door_pin 17
  # Check every 5sec
  @check_interval 5000

  # nil values only appear during the init call before
  # the first sensor read
  @type state :: %{
          door_gpio: GPIO.handle(),
          screen_gpio: GPIO.handle(),
          door_state: :open | :closed | nil,
          screen_state: :open | :closed | nil,
          state: :open | :door_closed | :screen_closed | :unknown
        }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, screen} = GPIO.open(@screen_pin, :input, pull_mode: :pullup)
    GPIO.set_interrupts(screen, :both)
    {:ok, door} = GPIO.open(@door_pin, :input, pull_mode: :pullup)
    GPIO.set_interrupts(door, :both)

    state = %{
      screen_gpio: screen,
      door_gpio: door,
      screen_state: nil,
      door_state: nil,
      state: nil
    }

    state =
      state
      |> read_sensors()
      |> infer_state()

    schedule_check()
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state.door_state, state}
  end

  def handle_info(:check_state, state) do
    new_state =
      state
      |> read_sensors()
      |> infer_state()

    if new_state != state do
      publish_state_change(new_state)
    end

    schedule_check()
    {:noreply, new_state}
  end

  def handle_info({:circuits_gpio, @door_pin, _timestamp, 0}, state) do
    state =
      %{state | door_state: :closed}
      |> infer_state()
      |> publish_state_change()

    {:noreply, state}
  end

  def handle_info({:circuits_gpio, @door_pin, _timestamp, 1}, state) do
    state =
      %{state | door_state: :open}
      |> infer_state()
      |> publish_state_change()

    {:noreply, state}
  end

  def handle_info({:circuits_gpio, @screen_pin, _timestamp, 0}, state) do
    state =
      %{state | screen_state: :closed}
      |> infer_state()
      |> publish_state_change()

    {:noreply, state}
  end

  def handle_info({:circuits_gpio, @screen_pin, _timestamp, 1}, state) do
    state =
      %{state | screen_state: :open}
      |> infer_state()
      |> publish_state_change()

    {:noreply, state}
  end

  @spec read_sensors(state()) :: state()
  def read_sensors(state) do
    state =
      case GPIO.read(state.door_gpio) do
        0 -> %{state | door_state: :open}
        1 -> %{state | door_state: :closed}
      end

    case GPIO.read(state.screen_gpio) do
      0 -> %{state | screen_state: :open}
      1 -> %{state | screen_state: :closed}
    end
  end

  @spec infer_state(state()) :: state()
  def infer_state(state) do
    case {state.door_state, state.screen_state} do
      {:open, :open} -> %{state | state: :open}
      {:closed, :open} -> %{state | state: :door_closed}
      {:open, :closed} -> %{state | state: :screen_closed}
      {:closed, :closed} -> %{state | state: :unknown}
    end
  end

  defp schedule_check do
    Process.send_after(self(), :check_state, @check_interval)
  end

  defp publish_state_change(state) do
    Logger.info("Garage screen state changed to: #{inspect(state)}")
    # publish to nats?
    state
  end

  # Client API
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end
end

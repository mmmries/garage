defmodule Garage.DoorMonitor do
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
          status: :open | :door_closed | :screen_closed | :unknown
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
      status: nil
    }

    state =
      state
      |> read_sensors()
      |> infer_status()

    schedule_check()
    {:ok, state}
  end

  def handle_call(:get_status, _from, state) do
    {:reply, state.status, state}
  end

  def handle_info(:check_state, state) do
    new_state =
      state
      |> read_sensors()
      |> infer_status()

    if new_state.status != state.status do
      publish_state_change(new_state)
    end

    schedule_check()
    {:noreply, new_state}
  end

  def handle_info({:circuits_gpio, pin, _timestamp, value}, state) do
    new_state =
      state
      |> read_sensors()
      |> infer_status()

    if new_state.status != state.status do
      publish_state_change(new_state)
    end

    {:noreply, new_state}
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

  @spec infer_status(state()) :: state()
  def infer_status(state) do
    case {state.door_state, state.screen_state} do
      {:open, :open} -> %{state | status: :open}
      {:closed, :open} -> %{state | status: :door_closed}
      {:open, :closed} -> %{state | status: :screen_closed}
      {:closed, :closed} -> %{state | status: :unknown}
    end
  end

  defp schedule_check do
    Process.send_after(self(), :check_state, @check_interval)
  end

  defp publish_state_change(state) do
    Logger.info("Garage screen state changed to: #{inspect(state)}")
    :ok = Gnat.pub(:gnat, "home.garage_door.status", Atom.to_string(state.status))
    state
  end

  # Client API
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
end

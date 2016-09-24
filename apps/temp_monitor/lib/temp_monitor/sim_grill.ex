defmodule TempMonitor.SimGrill do
  alias TempMonitor.SimGrill

  use GenServer

  defstruct ambient: 82,     # ambient temperature (minimum temperature for grill)
        temperature: 82,     # current temperature of the grill
        sample_time: nil,    # Timestamp at last sample (if any)
       blower_is_on: false,  # Is the grill's blower on?
            cooling: 10,     # degrees per second cooling
            heating: 20      # degrees per second heating when blower is on.

  @milliseconds_time_unit 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def get_temperature(grill) do
    GenServer.call(grill, :get_temperature)
  end

  def start_blower(grill) do
    GenServer.call(grill, :start_blower)
  end

  def stop_blower(grill) do
    GenServer.call(grill, :stop_blower)
  end

  def init(_args) do
    {:ok, %SimGrill{sample_time: grill_time()}}
  end

  def handle_call(:get_temperature, _from, grill_state) do
    new_grill = adjust_grill_temperature(grill_state)
    {:reply, new_grill.temperature, new_grill}
  end

  def handle_call(:start_blower, _from, grill_state) do
    {:reply, :ok, %SimGrill{adjust_grill_temperature(grill_state) | blower_is_on: true}}
  end

  def handle_call(:stop_blower, _from, grill_state) do
    {:reply, :ok, %SimGrill{adjust_grill_temperature(grill_state) | blower_is_on: false}}
  end

  def adjust_grill_temperature(grill = %SimGrill{sample_time: nil}) do
    %SimGrill{grill | sample_time: grill_time() }
  end

  def adjust_grill_temperature(grill = %SimGrill{sample_time: previous_time}) do
    # Calculate the elapsed time in seconds
    now = grill_time()
    elapsed_time = (now  - previous_time) / @milliseconds_time_unit

    new_temperature = grill.temperature + temperature_delta(grill, elapsed_time)

    new_temperature = max(grill.ambient, new_temperature)
    new_temperature = min(1500, new_temperature)

    %SimGrill{grill | sample_time: now, temperature: new_temperature }
  end

  def temperature_delta(grill = %SimGrill{blower_is_on: true}, elapsed_seconds) do
    (grill.heating - grill.cooling) * elapsed_seconds
  end

  def temperature_delta(grill, elapsed_seconds) do
    -grill.cooling * elapsed_seconds
  end

  def grill_time() do
    :erlang.monotonic_time(@milliseconds_time_unit)
  end
end
defmodule TempMonitor.TemperatureSampler do
  use GenServer

  defstruct name: :probe0, temperature_samples: [], 
    temperature_goal: 225.0, num_samples_taken: 0  # these are for mock/debugging

  @retained_sample_length 10

  def get_samples(sampler) do
    GenServer.call(sampler, :get_samples)
  end

  def start_link(name) when is_atom(name) do
    GenServer.start_link(__MODULE__, %__MODULE__{name: name}, name: name)
  end

  def init(state) do
    schedule_temp_check()
    {:ok, state}
  end

  def handle_call(:get_samples, _from, state) do
    {:reply, state.temperature_samples, state}
  end

  def handle_info(:new_temperature, state) do
    # do some work here
    {:ok, current_time} = NaiveDateTime.from_erl(:calendar.local_time())
    temperature = temperature_from_hardware(state)

    new_state = %__MODULE__{ state |
      temperature_samples: add_temperature_sample(state.temperature_samples, {current_time, temperature}),
      num_samples_taken: state.num_samples_taken + 1
      }

    Phoenix.PubSub.broadcast(TempMonitor.PubSub, pubsub_topic_name(new_state.name), %{samples: new_state.temperature_samples})

    schedule_temp_check()
    {:noreply, new_state}
  end

  defp add_temperature_sample(sample_list, new_sample) when is_list(sample_list) do
    Enum.take([new_sample | sample_list], @retained_sample_length)
  end

  defp temperature_from_hardware(state) do
    # Normally we'd actually go to the hardware for a temperature sample.  In this
    # case we simply calculate a fake temperature
    min(state.temperature_goal, state.temperature_goal * state.num_samples_taken / 30.0)
  end

  @millisecondsPerSecond 1000

  defp schedule_temp_check() do
    # do something to read a new temperature value
    Process.send_after(self(), :new_temperature, 1 * @millisecondsPerSecond)
  end

  defp pubsub_topic_name(probe_name) do
    "probe_samples:#{Atom.to_string(probe_name)}"
  end
end
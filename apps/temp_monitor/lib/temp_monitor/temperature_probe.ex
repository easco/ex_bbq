defmodule TempMonitor.TemperatureProbe do
	require BbqUi
	use GenServer

	defstruct temperature_samples: [], temperature_goal: 225.0, num_samples_taken: 0

	@retained_sample_length 10

	def start_link(name \\ nil) do
		GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
	end

	def init(state) do
		schedule_temp_check()
		{:ok, state}
	end

	def handle_info(:new_temperature, state) do
		# do some work here
		{:ok, current_time} = NaiveDateTime.from_erl(:calendar.local_time())
		temperature = temperature_from_hardware(state)

		new_state = %__MODULE__{ state |
			temperature_samples: add_temperature_sample(state.temperature_samples, {current_time, temperature}),
			num_samples_taken: state.num_samples_taken + 1
			}

		# IO.puts(inspect new_state)
		BbqUi.update_temperature_graph(new_state.temperature_samples)

		schedule_temp_check()
		{:noreply, new_state}
	end

	defp add_temperature_sample(sample_list, new_sample) when is_list(sample_list) do
		Enum.take([new_sample | sample_list], @retained_sample_length)
	end

	defp temperature_from_hardware(state) do
		min(state.temperature_goal, state.temperature_goal * state.num_samples_taken / 30.0)
	end

	@millisecondsPerSecond 1000

	defp schedule_temp_check() do
		# do something to read a new temperature value
		Process.send_after(self(), :new_temperature, 1 * @millisecondsPerSecond)
	end
end
defmodule BbqUi.TemperatureMgr do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts \\ nil) do
    IO.puts("subscribing")

    :ok = Phoenix.PubSub.subscribe(TempMonitor.PubSub, "probe_samples:probe0")
    {:ok, []}
  end

  def handle_info(msg = %{samples: temperature_data}, state) do
    update_temperature_graph(temperature_data)
    {:noreply, state}
  end

  # temperature data is assumed to be a list of tuples { NaiveDateTime, temperature }
  # where NaiveDateTime is a timestamp and temperature is a temperature value
  def update_temperature_graph(temperature_data) when is_list(temperature_data) do
      converted_data = temperature_data
        |> Enum.map(&convert_time_to_string/1)

      BbqUi.Endpoint.broadcast("temperature_data:lobby", "temperature_data", %{temperatures: converted_data})
  end

  defp convert_time_to_string({naive_date, temperature}) do
    time_as_string = naive_date |> NaiveDateTime.to_time |> Time.to_string
    %{ time: time_as_string, temperature: temperature }
  end
end
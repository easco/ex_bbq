defmodule BbqUi do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(BbqUi.Endpoint, []),
      # Start your own worker by calling: BbqUi.Worker.start_link(arg1, arg2, arg3)
      # worker(BbqUi.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BbqUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BbqUi.Endpoint.config_change(changed, removed)
    :ok
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

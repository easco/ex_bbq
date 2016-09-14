defmodule TempMonitor do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Task, [fn -> start_network end], restart: :transient),
      supervisor(Phoenix.PubSub.PG2, [TempMonitor.PubSub, []]),
      worker(TempMonitor.TemperatureSampler, [:probe0])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TempMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_network do
    # Nerves.InterimWiFi.setup "wlan0", ssid: "2WIRE091", key_mgmt: "WPA-PSK", psk: "9917351447"
  end
end

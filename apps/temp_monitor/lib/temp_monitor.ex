defmodule TempMonitor do
  use Application

  @interface :eth0
  @opts [mode: "static", ip: "10.0.10.3", mask: "16", subnet: "255.255.0.0"]

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Phoenix.PubSub.PG2, [Nerves.PubSub, [poolsize: 1]]),
      worker(Task, [fn -> start_network end], restart: :transient)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TempMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_network do
      Nerves.InterimWiFi.setup "wlan0", ssid: "2WIRE091", key_mgmt: "WPA-PSK", psk: "9917351447"
#    Nerves.Networking.setup @interface, @opts
  end

end

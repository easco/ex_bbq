defmodule BbqUi.BurnerController do
  use BbqUi.Web, :controller

  def burner(conn, params) do
    case params["burner"] do
      "on" ->
        switch_burner_on(conn)

      "off" ->
        switch_burner_off(conn)

      "toggle" ->
        IO.puts "Toggle"
        switch_burner_on(conn)

      _ ->
        conn |> send_resp(400, "")
    end
  end

  defp switch_burner_on(conn) do
    send_resp(conn, 201, "")
  end

  defp switch_burner_off(conn) do
    send_resp(conn, 201, "")
  end
end
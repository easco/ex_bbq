defmodule BbqUi.CookingController do
  use BbqUi.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
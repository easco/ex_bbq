defmodule BbqUi.CookingView do
  use BbqUi.Web, :view

  def js_module_file(conn, _template) do
    view_module(conn)
      |> Phoenix.Naming.resource_name("View")
      |> (&Kernel.<>/2).(".js")
  end
end

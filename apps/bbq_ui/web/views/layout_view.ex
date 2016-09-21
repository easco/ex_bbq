defmodule BbqUi.LayoutView do
  use BbqUi.Web, :view

  def js_module_file(conn, _template) do
    view_module(conn)
      |> Phoenix.Naming.resource_name("View")
      |> String.capitalize
      |> (&Kernel.<>/2).("Module")
  end
end

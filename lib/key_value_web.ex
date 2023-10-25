defmodule KeyValue.Web do
  use Plug.Router
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  def child_spec(_arg) do
    Plug.Cowboy.child_spec(
      scheme: :http,
      plug: __MODULE__,
      options: [port: Application.fetch_env!(:key_value, :http_port)]
    )
  end

  post "/entry/:key" do
    {status, body} =
      case conn.body_params do
        %{"value" => value} ->
          KeyValue.Server.put(key, value)
          {200, Poison.encode!(%{key: key, value: value, status: "Ok"})}

        _ ->
          {422, Poison.encode!(%{error: "missiong value"})}
      end

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(status, body)
  end

  get "/entry/:key" do
    value = KeyValue.Server.get(key)

    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, Poison.encode!(%{value: value}))
  end

  match _ do
    send_resp(conn, 404, "oops... Nothing here :(")
  end
end

defmodule SushiGoWeb.GameController do
  use SushiGoWeb, :controller

  @join_params_schema %{
    invite: [type: :string, required: true],
    player: [type: :string, required: true]
  }

  @spec join(Plug.Conn.t(), map) :: Plug.Conn.t()
  def join(conn, params) do
    with {:ok, validated_params} <- Tarams.cast(params, @join_params_schema) do
      game_path = ~p"/game/#{validated_params.invite}"

      conn
      |> put_session(:invite, validated_params.invite)
      |> put_session(:player, validated_params.player)
      |> redirect(to: game_path)
    else
      _ -> conn |> redirect(to: ~p"/")
    end
  end

  @spec leave(Plug.Conn.t(), any) :: Plug.Conn.t()
  def leave(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end


  @index_params_schema %{
    invite: [type: :string, required: true]
  }

  def index(conn, params) do
    with {:ok, validated_params} <- Tarams.cast(params, @index_params_schema) do
      conn
      |> put_session(:invite, validated_params.invite)
      # render game liveview
    else
      _ -> conn |> redirect(to: ~p"/")
    end
  end
end

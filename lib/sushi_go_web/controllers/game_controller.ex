defmodule SushiGoWeb.GameController do
  use SushiGoWeb, :controller

  alias SushiGoWeb.GameLive
  import Phoenix.LiveView.Controller

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

  def index(conn, params) do
    with player_id <- get_session(conn, :player), invite <- get_session(conn, :invite) do
      # Player doesn't have a session or is connected to another game
      if is_nil(player_id) or invite != params["invite"] do
        redirect(conn, to: ~p"/?#{%{invite: params["invite"]}}")
      else
        live_render(conn, GameLive,
          session: %{
            "invite" => invite,
            "player" => player_id
          }
        )
      end
    else
      _ -> redirect(conn, to: ~p"/?#{%{invite: params["invite"]}}")
    end
  end
end

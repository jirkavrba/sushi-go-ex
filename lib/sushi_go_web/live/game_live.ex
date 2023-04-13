defmodule SushiGoWeb.GameLive do
  use SushiGoWeb, :live_view

  alias SushiGo.GameServer

  def mount(_params, session, socket) do
    with %{"invite" => invite, "player" => player} <- session,
         {:ok, game} <- GameServer.find_game(invite),
         {:ok, player} <- GameServer.find_player(invite, player) do
      {:ok, assign(socket, game: game, player: player)}
    else
      _ -> {:ok, push_redirect(socket, to: ~p"/")}
    end
  end
end

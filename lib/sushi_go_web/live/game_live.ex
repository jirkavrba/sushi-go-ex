defmodule SushiGoWeb.GameLive do
  use SushiGoWeb, :live_view

  alias SushiGo.GameServer

  def mount(_params, session, socket) do
    with %{"invite" => invite, "player" => player} <- session,
         {:ok, game} <- GameServer.find_game(invite),
         {:ok, player} <- GameServer.find_player(invite, player),
         :ok <- Phoenix.PubSub.subscribe(SushiGo.PubSub, game.code.game_id) do
      {:ok, assign(socket, game: game, player: player)}
    else
      _ -> {:ok, push_redirect(socket, to: ~p"/")}
    end
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("leave", _params, socket) do
    %{game: game, player: player} = socket.assigns

    GameServer.leave(game.code.game_id, player)

    {:noreply, push_redirect(socket, to: ~p"/leave")}
  end
end

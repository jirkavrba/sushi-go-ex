defmodule SushiGoWeb.GameLive do
  use SushiGoWeb, :live_view

  alias SushiGo.Game
  alias SushiGo.GameServer

  def mount(_params, session, socket) do
    with %{"invite" => invite, "player" => player} <- session,
         {:ok, game} <- GameServer.find_game(invite),
         {:ok, player} <- GameServer.find_player(invite, player),
         :ok <- Phoenix.PubSub.subscribe(SushiGo.PubSub, game.code.game_id),
         :ok <- Phoenix.PubSub.subscribe(SushiGo.PubSub, "player:#{player.id}") do
      socket =
        socket
        |> assign(:game, game)
        |> assign(:player, extract_player(game, player.id))
        |> assign(:player_id, player.id)
        |> assign(:game_id, game.code.game_id)

      {:ok, socket}
    else
      _ -> {:ok, push_redirect(socket, to: ~p"/")}
    end
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    socket =
      socket
      |> assign(:game, game)
      |> assign(:player, extract_player(game, socket.assigns.player_id))

    {:noreply, socket}
  end

  def handle_event("leave", _params, socket) do
    %{game: game, player: player} = socket.assigns

    GameServer.leave(game.code.game_id, player)

    {:noreply, push_redirect(socket, to: ~p"/leave")}
  end

  def handle_event("start", _params, socket) do
    GameServer.start(socket.assigns.game_id, socket.assigns.player)
    {:noreply, socket}
  end

  def handle_event("pick-card", %{"card" => card}, socket) do
    GameServer.pick_card(
      socket.assigns.game_id,
      socket.assigns.player_id,
      String.to_existing_atom(card)
    )

    {:noreply, socket}
  end

  def handle_event("use-chopsticks", _params, socket) do
    GameServer.use_chopsticks(
      socket.assigns.game_id,
      socket.assigns.player_id
    )

    {:noreply, socket}
  end

  def handle_event("finish-picking", _params, socket) do
    GameServer.finish_picking(socket.assigns.game_id, socket.assigns.player_id)
    {:noreply, socket}
  end

  defp extract_player(%Game{players: players}, player_id) when is_binary(player_id) do
    Enum.find(players, nil, fn player -> player.id == player_id end)
  end
end

defmodule SushiGoWeb.GameLive do
  use SushiGoWeb, :live_view

  alias SushiGo.Player
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

  # View helpers
  def lane_class(%Player{} = player, current_player?) when is_boolean(current_player?) do
    cond do
      player.finished_picking and current_player? ->
        "bg-green-500 text-white"

      player.finished_picking and not current_player? ->
        "bg-gradient-to-r from-gray-500 to-green-500 text-white"

      current_player? ->
        "bg-blue-500"

      true ->
        "bg-gray-500 text-black"
    end
  end

  def card_image(card) when is_atom(card) do
    assigns = %{card: card}
    ~H"""
      <img class="w-12 h-12" src={"/images/#{@card}.png"}/>
    """
  end

  defp extract_player(%Game{players: players}, player_id) when is_binary(player_id) do
    Enum.find(players, nil, fn player -> player.id == player_id end)
  end
end

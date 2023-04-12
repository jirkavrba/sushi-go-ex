defmodule SushiGoWeb.LobbyLive do
  alias SushiGo.Player
  alias SushiGo.GameSupervisor
  alias SushiGo.GameServer
  alias SushiGo.GameCode
  use SushiGoWeb, :live_view

  def mount(params, _session, socket) do
    socket = socket
    |> assign(:player, "")
    |> assign(:valid, false)
    |> assign(:form, to_form(%{"username" => ""}))
    |> assign(:invite, params["invite"] || "")

    {:ok, socket}
  end

  def handle_event("validate-player", %{"username" => username}, socket) do
    {:noreply, assign(socket, valid: is_valid_username(username))}
  end

  def handle_event("create-player", %{"username" => username}, socket) do
    if is_valid_username(username) do
      {:noreply, assign(socket, player: username)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("create-new-game", _params, socket) do
    code = GameCode.new()
    player = Player.new(socket.assigns[:player])

    GameSupervisor.start_game(code)

    socket =
      case GameServer.join(code.game_id, player) do
        :ok ->
          socket
          |> push_redirect(to: ~p"/join?#{%{player: player.id, invite: code.game_code}}")

        {:error, _error} ->
          socket
      end

    {:noreply, socket}
  end

  @spec is_valid_username(String.t()) :: boolean()
  defp is_valid_username(username) when is_binary(username) do
    username
    |> String.trim()
    |> String.length() > 2
  end
end

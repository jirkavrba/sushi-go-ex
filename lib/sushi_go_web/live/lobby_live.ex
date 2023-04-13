defmodule SushiGoWeb.LobbyLive do
  alias SushiGo.Player
  alias SushiGo.GameSupervisor
  alias SushiGo.GameServer
  alias SushiGo.GameCode
  use SushiGoWeb, :live_view

  def mount(params, _session, socket) do
    invite = params["invite"] || ""

    socket =
      socket
      |> assign(:player, "")
      |> assign(:valid_username, false)
      |> assign(:valid_invite, is_valid_invite(invite))
      |> assign(:username_form, to_form(%{"username" => ""}))
      |> assign(:invite_form, to_form(%{"invite" => invite}))

    {:ok, socket}
  end

  def handle_event("validate-player", %{"username" => username}, socket) do
    {:noreply, assign(socket, valid_username: is_valid_username(username))}
  end

  def handle_event("validate-invite", %{"invite" => invite}, socket) do
    {:noreply, assign(socket, valid_invite: is_valid_invite(invite))}
  end

  def handle_event("create-player", %{"username" => username}, socket) do
    if is_valid_username(username) do
      {:noreply, assign(socket, player: username)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("create-game", _params, socket) do
    code = GameCode.new()
    player = Player.new(socket.assigns[:player])

    GameSupervisor.start_game(code)

    socket =
      case GameServer.join(code.game_id, player) do
        :ok ->
          socket
          |> push_redirect(to: ~p"/join?#{%{player: player.id, invite: code.game_code}}")

        {:error, error} ->
          dbg(error)
          socket
      end

    {:noreply, socket}
  end

  def handle_event("join-game", %{"invite" => invite}, socket) do
    code = GameCode.new(invite)
    player = Player.new(socket.assigns[:player])

    socket =
      case GameServer.join(code.game_id, player) do
        :ok ->
          socket
          |> push_redirect(to: ~p"/join?#{%{player: player.id, invite: code.game_code}}")

        {:error, error} ->
          dbg(error)
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

  @spec is_valid_invite(String.t()) :: boolean()
  defp is_valid_invite(invite) when is_binary(invite) do
    invite
    |> String.trim()
    |> String.match?(~r/^[a-z]+(-[a-z]+)+$/)
  end
end

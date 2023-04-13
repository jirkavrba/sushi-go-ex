defmodule SushiGoWeb.LobbyLive do
  use SushiGoWeb, :live_view

  alias SushiGo.Player
  alias SushiGo.GameSupervisor
  alias SushiGo.GameServer
  alias SushiGo.GameCode

  def mount(params, _session, socket) do
    invite = params["invite"] || ""

    socket =
      socket
      |> assign(:player, "")
      |> assign(:valid_username, false)
      |> assign(:valid_invite, is_valid_invite(invite))
      |> assign(:username_form, to_form(%{"username" => ""}))
      |> assign(:invite_form, to_form(%{"invite" => invite}))
      |> assign(:error, nil)

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
          |> assign(:error, nil)
          |> push_redirect(to: ~p"/join?#{%{player: player.id, invite: code.game_code}}")

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("join-game", %{"invite" => invite}, socket) do
    code = GameCode.new(String.upcase(invite))
    player = Player.new(socket.assigns[:player])

    socket =
      case GameServer.join(code.game_id, player) do
        :ok ->
          socket
          |> assign(:error, nil)
          |> push_redirect(to: ~p"/join?#{%{player: player.id, invite: code.game_code}}")

        {:error, :game_not_found} ->
          socket
          |> assign(:error, "Game was not found!")

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @spec format_invite(String.t()) :: String.t()
  def format_invite(invite) when is_binary(invite) do
    invite
    |> String.trim()
    |> String.upcase()
  end

  @spec is_valid_username(String.t()) :: boolean()
  defp is_valid_username(username) when is_binary(username) do
    username
    |> String.trim()
    |> String.length() >= 2
  end

  @spec is_valid_invite(String.t()) :: boolean()
  defp is_valid_invite(invite) when is_binary(invite) do
    invite
    |> format_invite()
    |> String.match?(~r/^[A-Z]{3}$/)
  end
end

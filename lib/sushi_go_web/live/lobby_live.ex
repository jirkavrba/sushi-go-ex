defmodule SushiGoWeb.LobbyLive do
  use SushiGoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, player: "", valid: false, form: to_form(%{"username" => ""}))}
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

  @spec is_valid_username(String.t()) :: boolean()
  defp is_valid_username(username) when is_binary(username) do
    username
      |> String.trim()
      |> String.length() > 2
  end

end

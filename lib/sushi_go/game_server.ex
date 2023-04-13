defmodule SushiGo.GameServer do
  @moduledoc """
  Module representing a single game server that manages a game instance.
  """

  use GenServer

  require Logger

  alias SushiGo.Game
  alias SushiGo.GameCode
  alias SushiGo.Player

  @impl GenServer
  def init(%GameCode{} = code) do
    Logger.info("Starting a new game server with code #{code.game_code} and id #{code.game_id}")
    {:ok, %{game: Game.new(code)}}
  end

  def start_link(%GameCode{} = code) do
    GenServer.start(__MODULE__, code, name: via_tuple(code.game_id))
  end

  @spec join(String.t(), Player.t()) :: :ok | {:error, :game_not_found | :game_started}
  def join(game_id, %Player{} = player) when is_binary(game_id) do
    with {:ok, updated_game} <- call_by_name(game_id, {:join, player}) do
      broadcast!(game_id, :game_updated, updated_game)
    end
  end

  @spec leave(String.t(), Player.t()) :: :ok | {:error, :game_not_found | :player_not_found}
  def leave(game_id, %Player{} = player) when is_binary(game_id) do
    with {:ok, updated_game} <- call_by_name(game_id, {:leave, player}) do
      broadcast!(game_id, :game_updated, updated_game)
    end
  end

  @spec start(String.t(), Player.t()) :: :ok | {:error, :game_not_found | :game_started}
  def start(game_id, %Player{} = player) when is_binary(game_id) do
    with {:ok, updated_game} <- call_by_name(game_id, {:start, player}) do
      broadcast!(game_id, :game_updated, updated_game)
    end
  end

  @spec pick_card(String.t(), String.t(), Cards.card()) :: :ok
  def pick_card(game_id, player_id, card) when is_binary(game_id) and is_binary(player_id) do
    with {:ok, updated_game} <- call_by_name(game_id, {:pick_card, player_id, card}) do
      broadcast!(game_id, :game_updated, updated_game)
    end
  end

  @spec use_chopsticks(String.t(), String.t()) :: :ok
  def use_chopsticks(game_id, player_id) when is_binary(game_id) and is_binary(player_id) do
    with {:ok, updated_game} <- call_by_name(game_id, {:use_chopsticks, player_id}) do
      broadcast!(game_id, :game_updated, updated_game)
    end
  end

  @spec finish_picking(String.t(), String.t()) :: :ok
  def finish_picking(game_id, player_id) when is_binary(game_id) and is_binary(player_id) do
    with {:ok, updated_game} <- call_by_name(game_id, {:finish_picking, player_id}) do
      broadcast!(game_id, :game_updated, updated_game)
    end
  end

  @spec find_game(String.t()) :: {:ok, Game.t()} | {:error, :game_not_found}
  def find_game(invite) when is_binary(invite) do
    invite
    |> invite_to_game_id()
    |> call_by_name(:find_game)
  end

  @spec find_player(String.t(), String.t()) :: {:ok, Player.t()} | {:error, :player_not_found}
  def find_player(invite, player_id) when is_binary(invite) and is_binary(player_id) do
    invite
    |> invite_to_game_id()
    |> call_by_name({:find_player, player_id})
  end

  # GenServer methods

  @impl GenServer
  def handle_call({:join, player}, _from, state) do
    case Game.join(state.game, player) do
      {:ok, game} ->
        {:reply, {:ok, game}, %{state | game: game}}

      error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:leave, player}, _from, state) do
    {:ok, game} = Game.leave(state.game, player)
    {:reply, {:ok, game}, %{state | game: game}}
  end

  @impl GenServer
  def handle_call({:start, _player}, _from, state) do
    # TODO: Log who started the game to the game chat
    updated_game = Game.start_new_round(state.game)
    {:reply, {:ok, updated_game}, %{state | game: updated_game}}
  end

  @impl GenServer
  def handle_call({:pick_card, player_id, card}, _from, state) do
    updated_game = Game.pick_card(state.game, player_id, card)
    {:reply, {:ok, updated_game}, %{state | game: updated_game}}
  end

  @impl GenServer
  def handle_call({:use_chopsticks, player_id}, _from, state) do
    updated_game = Game.use_chopsticks(state.game, player_id)
    {:reply, {:ok, updated_game}, %{state | game: updated_game}}
  end

  @impl GenServer
  def handle_call({:finish_picking, player_id}, _from, state) do
    updated_game = Game.finish_picking(state.game, player_id)
    {:reply, {:ok, updated_game}, %{state | game: updated_game}}
  end

  @impl GenServer
  def handle_call(:find_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call({:find_player, player_id}, _from, state) do
    {:reply, Game.find_player(state.game, player_id), state}
  end

  # Helper methods

  @spec invite_to_game_id(String.t()) :: String.t()
  defp invite_to_game_id(invite) when is_binary(invite) do
    invite
    |> GameCode.new()
    |> Map.get(:game_id)
  end

  @type via_query :: {:via, Registry, {SushiGo.GameRegistry, String.t()}}

  @spec via_tuple(String.t()) :: via_query()
  defp via_tuple(game_id) do
    {:via, Registry, {SushiGo.GameRegistry, game_id}}
  end

  @spec find_game_pid(String.t()) :: pid() | nil
  def find_game_pid(game_id) when is_binary(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  @spec call_by_name(String.t(), any()) :: term()
  defp call_by_name(game_id, query) when is_binary(game_id) do
    case find_game_pid(game_id) do
      game_pid when is_pid(game_pid) -> GenServer.call(game_pid, query)
      nil -> {:error, :game_not_found}
    end
  end

  @spec broadcast!(String.t(), atom(), map()) :: :ok
  defp broadcast!(channel_id, event, payload) do
    Phoenix.PubSub.broadcast!(SushiGo.PubSub, channel_id, %{event: event, payload: payload})
  end
end

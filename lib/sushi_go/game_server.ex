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
    with {:ok, players} <- call_by_name(game_id, {:join, player}) do
      broadcast!(game_id, :players_updated, players)
    end
  end

  # GenServer methods

  @impl GenServer
  def handle_call({:join, player}, _from, state) do
    case Game.join(state.game, player) do
      {:ok, game} ->
        {:reply, {:ok, game.players}, %{state | game: game}}

      error ->
        {:reply, error, state}
    end
  end

  @type via_query :: {:via, Registry, {SushiGo.GameRegistry, String.t()}}

  @spec via_tuple(String.t()) :: via_query()
  defp via_tuple(game_id) do
    {:via, Registry, {SushiGo.GameRegistry, game_id}}
  end

  @spec find_game_pid(String.t()) :: pid() | nil
  def find_game_pid(game_id) do
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

  @spec cast_by_name(String.t(), any()) :: :ok
  defp cast_by_name(game_id, query) when is_binary(game_id) do
    case find_game_pid(game_id) do
      game_pid when is_pid(game_pid) -> GenServer.cast(game_pid, query)
      nil -> {:error, :game_not_found}
    end
  end

  @spec broadcast!(String.t(), atom(), map()) :: :ok
  defp broadcast!(game_id, event, payload) do
    Phoenix.PubSub.broadcast!(SushiGo.PubSub, game_id, %{event: event, payload: payload})
  end
end

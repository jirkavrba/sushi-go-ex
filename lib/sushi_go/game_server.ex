defmodule SushiGo.GameServer do
  @moduledoc """
  Module representing a single game server that manages a game instance.
  """

  use GenServer

  require Logger

  alias SushiGo.Game
  alias SushiGo.GameCode

  @impl GenServer
  def init(%GameCode{} = code)  do
    Logger.info("Starting a new game server with code #{code.game_code} and id #{code.game_id}")
    {:ok, %{game: Game.new(code)}}
  end

  def start_link(%GameCode{} = code) do
    GenServer.start(__MODULE__, code, name: via_tuple(code.game_id))
  end

  @spec find_game_pid(String.t()) :: pid() | nil
  def find_game_pid(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  @type via_query :: {:via, Registry, {SushiGo.GameRegistry, String.t()}}

  @spec via_tuple(String.t()) :: via_query()
  defp via_tuple(game_id) do
    {:via, Registry, {SushiGo.GameRegistry, game_id}}
  end
end

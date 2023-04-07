defmodule GameServer do
  use GenServer

  require Logger

  alias SushiGo.Game
  alias SushiGo.GameCode

  @impl GenServer
  def init(%GameCode{} = code)  do
    Logger.info("Starting a new game server with code #{code.game_code} and id #{code.game_id}")
    {:ok, %{game: Game.new(code)}}
  end

  def game_pid(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  @spec via_tuple(String.t()) :: {:via, Registry, {SushiGo.GameRegistry, String.t()}}
  defp via_tuple(game_id) do
    {:via, Registry, {SushiGo.GameRegistry, game_id}}
  end
end

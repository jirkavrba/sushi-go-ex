defmodule SushiGo.GameSupervisor do
  @moduledoc """
  A module for dynamically staring and stopping supervised game servers.
  """
  alias SushiGo.GameCode
  alias SushiGo.GameServer

  use DynamicSupervisor

  @impl true
  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_game(%GameCode{} = code) do
    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [code]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @spec stop_game(GameCode.t()) :: :ok
  def stop_game(%GameCode{game_id: id}) do
    stop_game(id)
  end

  @spec stop_game(String.t()) :: :ok
  def stop_game(game_id) when is_binary(game_id) do
    case GameServer.find_game_pid(game_id) do
      pid when is_pid(pid) -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      nil -> :ok
    end
  end

  def which_children() do
    Supervisor.which_children(__MODULE__)
  end
end

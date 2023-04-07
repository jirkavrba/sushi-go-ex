defmodule SushiGo.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias SushiGo.GameSupervisor
  alias SushiGo.GameServer
  alias SushiGo.GameCode

  test "game servers can be created" do
    %GameCode{game_id: id} = code = GameCode.new()

    assert {:ok, pid} = GameSupervisor.start_game(code)

    assert Process.alive?(pid)
    assert pid == GameServer.find_game_pid(id)
  end
end

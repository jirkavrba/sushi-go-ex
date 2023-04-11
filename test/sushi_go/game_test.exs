defmodule SushiGo.GameTest do
  alias SushiGo.Player
  alias SushiGo.GameCode
  alias SushiGo.Game

  use ExUnit.Case

  test "adding players to a game that has not been started" do
    code = GameCode.new()
    game = Game.new(code)

    assert length(game.players) == 0
    assert game.started == false

    player = Player.new("jirka")
    game = Game.join(game, player)

    assert length(game.players) == 1
    assert hd(game.players) == player
    assert game.started == false
  end

  test "adding players to a game that has been already started" do
    code = GameCode.new()
    game = %Game{
      code: code,
      round: 1,
      started: true,
      players: [
        Player.new("jirka"),
        Player.new("elinka")
      ],
    }

    assert length(game.players) == 2
    assert game.started == true

    player = Player.new("another one")
    game = Game.join(game, player)

    assert length(game.players) == 2
    assert game.started == true
  end
end

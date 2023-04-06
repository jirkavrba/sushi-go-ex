defmodule SushiGo.CardsTest do
  use ExUnit.Case
  alias SushiGo.Cards

  test "deck can be created with all puddings" do
    deck = Cards.create_game_deck()

    assert length(deck) == 108
    assert length(Enum.filter(deck, &(&1 == :pudding))) == 10
  end

  test "deck can be created with some puddings" do
    deck = Cards.create_game_deck(5)

    assert length(deck) == 103
    assert length(Enum.filter(deck, &(&1 == :pudding))) == 5
  end

  test "deck can be created with no puddings" do
    deck = Cards.create_game_deck(100)

    assert length(deck) == 98
    assert length(Enum.filter(deck, &(&1 == :pudding))) == 0
  end
end

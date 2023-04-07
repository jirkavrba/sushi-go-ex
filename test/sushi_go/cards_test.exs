defmodule SushiGo.CardsTest do
  @moduledoc false

  use ExUnit.Case, async: true
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
    assert deck
          |> Enum.filter(&(&1 == :pudding))
          |> Enum.empty?()
  end

  test "scoring includes maki points" do
    assert Cards.score([], 6) == 6
  end

  test "scoring tempuras" do
    assert Cards.score(List.duplicate(:tempura, 1)) == 0
    assert Cards.score(List.duplicate(:tempura, 2)) == 5
    assert Cards.score(List.duplicate(:tempura, 3)) == 5
    assert Cards.score(List.duplicate(:tempura, 4)) == 10
    assert Cards.score(List.duplicate(:tempura, 5)) == 10
  end

  test "scoring sashimis" do
    assert Cards.score(List.duplicate(:sashimi, 1)) == 0
    assert Cards.score(List.duplicate(:sashimi, 2)) == 0
    assert Cards.score(List.duplicate(:sashimi, 3)) == 10
    assert Cards.score(List.duplicate(:sashimi, 4)) == 10
    assert Cards.score(List.duplicate(:sashimi, 5)) == 10
    assert Cards.score(List.duplicate(:sashimi, 6)) == 20
    assert Cards.score(List.duplicate(:sashimi, 7)) == 20
  end

  test "scoring nigiri" do
    # 3 * 1 + 2 + 2 = 7
    assert Cards.score([:wasabi, :egg_nigiri, :salmon_nigiri, :sashimi, :tempura, :salmon_nigiri]) == 7

    # 1 + 3 * 3 + 3 * 2 + 2 = 18
    assert Cards.score([:egg_nigiri, :tempura, :wasabi, :sashimi, :squid_nigiri, :pudding, :wasabi, :salmon_nigiri, :salmon_nigiri]) == 18
  end

  test "scoring dumplings" do
    assert Cards.score(List.duplicate(:dumpling, 0)) == 0
    assert Cards.score(List.duplicate(:dumpling, 1)) == 1
    assert Cards.score(List.duplicate(:dumpling, 2)) == 3
    assert Cards.score(List.duplicate(:dumpling, 3)) == 6
    assert Cards.score(List.duplicate(:dumpling, 4)) == 10
    assert Cards.score(List.duplicate(:dumpling, 5)) == 15
    assert Cards.score(List.duplicate(:dumpling, 6)) == 15
  end
end

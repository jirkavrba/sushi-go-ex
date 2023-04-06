defmodule SushiGo.Cards do
  @type card ::
          :egg_nigiri
          | :salmon_nigiri
          | :squid_nigiri
          | :one_maki
          | :two_maki
          | :three_maki
          | :tempura
          | :sashimi
          | :wasabi
          | :dumpling
          | :pudding
          | :chopsticks

  @type deck :: list(card)

  @spec create_game_deck(integer()) :: deck
  def create_game_deck(puddings_excluded \\ 0) when is_integer(puddings_excluded) do
    [
      List.duplicate(:tempura, 14),
      List.duplicate(:sashimi, 14),
      List.duplicate(:dumplings, 14),
      List.duplicate(:one_maki, 6),
      List.duplicate(:two_maki, 12),
      List.duplicate(:three_maki, 8),
      List.duplicate(:egg_nigiri, 5),
      List.duplicate(:salmon_nigiri, 10),
      List.duplicate(:squid_nigiri, 5),
      List.duplicate(:wasabi, 6),
      List.duplicate(:chopsticks, 4),
      List.duplicate(:pudding, 10 - min(puddings_excluded, 10))
    ]
    |> Enum.concat()
    |> Enum.shuffle()
  end

  @spec count_maki(list(card())) :: integer()
  def(count_maki(cards) when is_list(cards)) do
    cards
    |> Enum.map(fn :one_maki -> 1; :two_maki -> 2; :three_maki -> 3; _ -> 0 end)
    |> Enum.sum()
  end

  @spec score(list(card()), integer()) :: integer()
  def score(cards, maki_points \\ 0) when is_list(cards) and is_integer(maki_points) do
    count_type = fn enum, type -> Enum.count(enum, &(&1 == type)) end

    Enum.sum([
      # Maki points are scored globally for the whole room
      maki_points,

      # Every pair of tempuras is worth 5 points
      floor(count_type.(cards, :tempura) / 2) * 5,

      # Every triplet of sashimi is worth 10 points
      floor(count_type.(cards, :sashimi) / 3) * 10,

      # Nigiri can be tripled in value by using wasabi
      score_nigiri(cards),

      # Dumplings are scored based on the number of cards owned
      case count_type.(cards, :dumpling) do
        0 -> 0
        1 -> 1
        2 -> 3
        3 -> 6
        4 -> 10
        _ -> 15
      end
    ])
  end

  @spec score_nigiri(list(card())) :: integer()
  defp score_nigiri(cards) when is_list(cards) do
    cards
    |> Enum.map(fn :wasabi -> :wasabi; :egg_nigiri -> 1; :salmon_nigiri -> 2; :squid_nigiri -> 3; _ -> nil end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce({1, 0}, fn card, {wasabi_multiplier, points} ->
      if (card == :wasabi),
        do: {3, points},
        else: {1, points + card * wasabi_multiplier}
    end)
    |> then(fn {_, points} -> points end)
  end

end

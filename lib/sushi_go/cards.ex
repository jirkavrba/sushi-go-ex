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

  @type deck :: [card]

  @spec create_game_deck(integer()) :: deck
  def create_game_deck(puddings_excluded \\ 0) do
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
      List.duplicate(:pudding, 10 - min(puddings_excluded, 10)),
    ]
    |> Enum.concat()
    |> Enum.shuffle()
  end
end

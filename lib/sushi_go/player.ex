defmodule SushiGo.Player do
  defmodule State do
    @moduledoc """
    A simple struct representing state for every player within the game round
    """

    @type t :: %__MODULE__{
      collected_cards: list(card()),
      available_cards: list(card()),
      picked_cards: list(card()),
      finished_picking: boolean,
      puddings: integer,
    }

    @enforce_keys [:collected_cards, :available_cards, :picked_cards]

    defstruct [:collected_cards, :available_cards, :picked_cards, finished_picking: false, puddings: 0]
  end
end

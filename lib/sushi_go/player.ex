defmodule SushiGo.Player do
  @moduledoc """
  Module representing a player that's playing the game.
  """

  alias SushiGo.Cards

  @type t :: %__MODULE__{
          id: String.t(),
          username: String.t(),
          collected_cards: list(Cards.card()),
          available_cards: list(Cards.card()),
          picked_cards: list(Cards.card()),
          finished_picking: boolean(),
          puddings: integer(),
          accumulated_score: integer()
        }

  @enforce_keys [:id, :username, :collected_cards, :available_cards, :picked_cards]

  defstruct [
    :id,
    :username,
    :collected_cards,
    :available_cards,
    :picked_cards,
    finished_picking: false,
    puddings: 0,
    accumulated_score: 0
  ]

  @spec new(String.t()) :: t()
  def new(username) when is_binary(username) do
    %__MODULE__{
      id: UUID.uuid4(),
      username: username,
      collected_cards: [],
      available_cards: [],
      picked_cards: []
    }
  end
end

defmodule SushiGo.Game do
  @moduledoc """
  A module representing the state of a single game.
  This struct is used in game servers to keep track of the game state and perform player actions.
  """

  alias SushiGo.GameCode
  alias SushiGo.Player

  @type t :: %__MODULE__{
          code: GameCode.t(),
          players: list(Player.t()),
          round: integer()
        }

  @enforce_keys [:code, :players, :round]

  defstruct [:code, :players, :round]

  @spec new() :: t()
  def new() do
    %__MODULE__{
      code: GameCode.new(),
      players: [],
      round: 0
    }
  end

  @spec add_player(t(), Player.t()) :: t()
  def add_player(%__MODULE__{} = game, %Player{} = player) do
    %__MODULE__{game | players: game.players ++ [player]}
  end
end

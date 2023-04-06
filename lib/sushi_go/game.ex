defmodule SushiGo.Game do
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
  def add_player(%Game{} = game, %Player{} = player) do
    %Game{game | players: game.players ++ [player]}
  end
end

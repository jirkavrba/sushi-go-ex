defmodule SushiGo.Game do
  @moduledoc """
  A module representing the state of a single game.
  This struct is used in game servers to keep track of the game state and perform player actions.
  """

  alias SushiGo.Cards
  alias SushiGo.GameCode
  alias SushiGo.Player

  @type t :: %__MODULE__{
          code: GameCode.t(),
          players: list(Player.t()),
          round: integer(),
          started: boolean()
        }

  @enforce_keys [:code, :players, :round]

  defstruct [:code, :players, :round, started: false]

  @spec new(GameCode.t()) :: t()
  def new(%GameCode{} = code) do
    %__MODULE__{
      code: code,
      players: [],
      round: 0,
      started: false
    }
  end

  @doc "Add a new player to the game"
  @spec add_player(t(), Player.t()) :: t()
  def add_player(%__MODULE__{ started: true } = game, %Player{}), do: game
  def add_player(%__MODULE__{} = game, %Player{} = player) do
    %__MODULE__{game | players: game.players ++ [player]}
  end


  @doc "Start a new game round together with dealing players new cards"
  @spec start_new_round(t()) :: t()
  def start_new_round(%__MODULE__{} = game) do
    total_puddings =
      game.players
      |> Enum.flat_map(fn player -> player.collected_cards end)
      |> Enum.count(fn card -> card == :pudding end)

    deck = Cards.create_game_deck(total_puddings)

    hand_size =
      case length(game.players) do
        2 -> 10
        3 -> 9
        4 -> 8
        5 -> 7
        _ -> 6
      end

    updated_players =
      game.players
      |> Enum.with_index()
      |> Enum.map(fn {player, index} ->
        hand =
          deck
          |> Enum.drop(index * hand_size)
          |> Enum.take(hand_size)

        %Player{
          player
          | available_cards: hand,
            collected_cards: [],
            picked_cards: [],
            finished_picking: false
        }
      end)

    %__MODULE__{game | round: game.round + 1, players: updated_players}
  end
end

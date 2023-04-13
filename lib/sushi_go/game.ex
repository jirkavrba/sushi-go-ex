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

  @doc "Join the game as a new player"
  @spec join(t(), Player.t()) :: {:ok, t()} | {:error, atom()}
  def join(%__MODULE__{started: true}, %Player{}), do: {:error, :game_started}

  def join(%__MODULE__{} = game, %Player{} = player) do
    {:ok, %__MODULE__{game | players: game.players ++ [player]}}
  end

  @spec find_player(t(), String.t()) :: {:ok, Player.t()} | {:error, :player_not_found}
  def find_player(%__MODULE__{} = game, player_id) when is_binary(player_id) do
    game.players
    |> Enum.find(fn %Player{id: id} -> id == player_id end)
    |> then(fn
      nil -> {:error, :player_not_found}
      player -> {:ok, player}
    end)
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

  @spec finish_round(t()) :: t()
  def finish_round(%__MODULE__{} = game) do
    maki_leaderboard =
      game.players
      |> Enum.map(fn %Player{collected_cards: cards} = player ->
        {player, Cards.count_maki(cards)}
      end)
      |> Enum.sort_by(fn {_, maki} -> maki end, :desc)

    maki_is_tie = elem(maki_leaderboard[0], 0) == elem(maki_leaderboard[1], 0)

    updated_players =
      game.players
      |> Enum.map(fn %Player{} = player ->
        maki_index = Enum.find_index(maki_leaderboard, fn {p, _} -> p == player end)

        maki_points =
          cond do
            maki_is_tie and maki_index < 2 -> 3
            not maki_is_tie and maki_index == 0 -> 6
            not maki_is_tie and maki_index == 1 -> 3
            true -> 0
          end

        score = Cards.score(player.collected_cards, maki_points)
        puddings = Enum.count(player.collected_cards, fn item -> item == :pudding end)

        %Player{
          player
          | accumulated_score: player.accumulated_score + score,
            puddings: player.puddings + puddings
        }
      end)

    %__MODULE__{game | players: updated_players}
  end

  @spec pick_card(t(), Player.t(), Cards.card()) :: t()
  def pick_card(%__MODULE__{} = game, player_id, card) do
    updated_players =
      game.players
      |> Enum.map(fn %Player{} = player ->
        if player.id == player_id and Enum.member?(player.available_cards, card) do
          %Player{
            player
            | picked_cards: [card],
              available_cards: (player.available_cards -- [card]) ++ player.picked_cards
          }
        else
          player
        end
      end)

    %__MODULE__{game | players: updated_players}
  end

  @spec swap_with_chopsticks(t(), String.t(), Cards.card()) :: t()
  def swap_with_chopsticks(%__MODULE__{} = game, player_id, card) do
    updated_players =
      game.players
      |> Enum.map(fn %Player{} = player ->
        if player.id == player_id and Enum.member?(player.available_cards, card) and
             Enum.member?(player.collected_cards, :chopsticks) do
          %Player{
            player
            | picked_cards: player.picked_cards ++ ([card] -- [:chopsticks]),
              available_cards: (player.available_cards -- [card]) ++ [:chopsticks]
          }
        else
          player
        end
      end)

    %__MODULE__{game | players: updated_players}
  end
end

defmodule SushiGo.Game do
  @moduledoc """
  A module representing the state of a single game.
  This struct is used in game servers to keep track of the game state and perform player actions.
  """

  alias SushiGo.Cards
  alias SushiGo.GameCode
  alias SushiGo.Player

  require Integer

  @type t :: %__MODULE__{
          code: GameCode.t(),
          players: list(Player.t()),
          round: integer(),
          started: boolean(),
          finished: boolean()
        }

  @enforce_keys [:code, :players, :round]

  defstruct [:code, :players, :round, started: false, finished: false]

  @spec new(GameCode.t()) :: t()
  def new(%GameCode{} = code) do
    %__MODULE__{
      code: code,
      players: [],
      round: 0,
      started: false,
      finished: false
    }
  end

  # TODO: Make this configurable in lobby?
  @game_rounds 3

  @doc "Join the game as a new player"
  @spec join(t(), Player.t()) :: {:ok, t()} | {:error, atom()}
  def join(%__MODULE__{started: true}, %Player{}), do: {:error, :game_started}

  def join(%__MODULE__{} = game, %Player{} = player) do
    {:ok, %__MODULE__{game | players: game.players ++ [player]}}
  end

  @spec leave(t(), Player.t()) :: {:ok, t()}
  def leave(%__MODULE__{} = game, %Player{} = player) do
    # TODO: Delete games with < 1 player?
    {:ok, %__MODULE__{game | players: game.players -- [player]}}
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

    %__MODULE__{game | started: true, round: game.round + 1, players: updated_players}
  end

  @spec finish_round(t()) :: t()
  def finish_round(%__MODULE__{} = game) do
    maki_leaderboard =
      game.players
      |> Enum.map(fn %Player{collected_cards: cards} = player ->
        {player, Cards.count_maki(cards)}
      end)
      |> Enum.sort_by(fn {_, maki} -> maki end, :desc)

    [first, second] = Enum.take(maki_leaderboard, 2)
    maki_is_tie = elem(first, 1) == elem(second, 1)

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

    start_new_round(%__MODULE__{game | players: updated_players})
  end

  @spec finish_game(t()) :: t()
  def finish_game(%__MODULE__{} = game) do
    puddings = Enum.map(game.players, fn %Player{puddings: puddings} -> puddings end)
    max_puddings = Enum.max(puddings)
    min_puddings = Enum.min(puddings)

    updated_players =
      game.players
      |> Enum.map(fn %Player{puddings: puddings} = player ->
        cond do
          puddings == max_puddings ->
            %Player{player | accumulated_score: player.accumulated_score + 6}

          puddings == min_puddings ->
            %Player{player | accumulated_score: player.accumulated_score - 6}

          true ->
            player
        end
      end)

    %__MODULE__{game | players: updated_players, finished: true}
  end

  @spec rotate_cards(t()) :: t()
  def rotate_cards(%__MODULE__{} = game) do
    shift = if Integer.is_even(game.round), do: -1, else: 1
    cards = Enum.map(game.players, fn %Player{available_cards: cards} -> cards end)
    total_players = length(game.players)

    updated_players =
      game.players
      |> Enum.with_index()
      |> Enum.map(fn {%Player{} = player, index} ->
        new_cards = Enum.at(cards, Integer.mod(total_players + index + shift, total_players))

        %Player{
          player
          | collected_cards: player.collected_cards ++ player.picked_cards,
            available_cards: new_cards,
            picked_cards: [],
            finished_picking: false
        }
      end)

    %__MODULE__{game | players: updated_players}
  end

  @spec pick_card(t(), String.t(), Cards.card()) :: t()
  def pick_card(%__MODULE__{} = game, player_id, card) do
    updated_players =
      game.players
      |> Enum.map(fn %Player{} = player ->
        if player.id == player_id and Enum.member?(player.available_cards, card) do
          cards = if player.used_chopsticks, do: 2, else: 1
          new_stack = [card] ++ player.picked_cards
          new_picked_cards = Enum.take(new_stack, cards)
          new_available_cards = Enum.drop(new_stack, cards)

          %Player{
            player
            | picked_cards: new_picked_cards,
              available_cards: (player.available_cards -- [card]) ++ new_available_cards
          }
        else
          player
        end
      end)

    %__MODULE__{game | players: updated_players}
  end

  @spec use_chopsticks(t(), String.t()) :: t()
  def use_chopsticks(%__MODULE__{} = game, player_id) do
    updated_players =
      game.players
      |> Enum.map(fn %Player{} = player ->
        if player.id == player_id and Enum.member?(player.collected_cards, :chopsticks) do
          %Player{
            player
            | collected_cards: player.collected_cards -- [:chopsticks],
              available_cards: player.available_cards ++ [:chopsticks],
              used_chopsticks: true
          }
        else
          player
        end
      end)

    %__MODULE__{game | players: updated_players}
  end

  @spec finish_picking(t(), String.t()) :: t()
  def finish_picking(%__MODULE__{} = game, player_id) do
    updated_players =
      game.players
      |> Enum.map(fn %Player{} = player ->
        expected_picked_cards = if player.used_chopsticks, do: 2, else: 1

        if player.id == player_id and length(player.picked_cards) == expected_picked_cards do
          %Player{player | finished_picking: true, used_chopsticks: false}
        else
          player
        end
      end)

    updated_game = %__MODULE__{game | players: updated_players}

    all_players_finished_picking? =
      Enum.all?(updated_players, fn %Player{} = player -> player.finished_picking end)

    all_cards_have_been_picked? =
      Enum.all?(updated_players, fn %Player{} = player -> Enum.empty?(player.available_cards) end)

    updated_game
    |> then(fn game -> if all_players_finished_picking?, do: rotate_cards(game), else: game end)
    |> then(fn game -> if all_cards_have_been_picked?, do: finish_round(game), else: game end)
    |> then(fn game -> if game.round > @game_rounds, do: finish_game(game), else: game end)
  end
end

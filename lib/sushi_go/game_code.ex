defmodule SushiGo.GameCode do
  @moduledoc """
  A module representing code that can be used to join games.
  A game ID can be derived from the game code by hashing it's mnemonic words into a single number.
  """

  @type t :: %__MODULE__{
          game_code: String.t(),
          game_id: String.t()
        }

  @enforce_keys [:game_code, :game_id]

  defstruct [:game_code, :game_id]

  @spec new() :: t()
  def new(), do: new(generate_code())

  @spec new(String.t()) :: t()
  def new(game_code) when is_binary(game_code) do
    %__MODULE__{
      game_code: game_code,
      game_id: generate_game_id(game_code)
    }
  end

  @spec generate_code() :: String.t()
  defp generate_code() do
    for _ <- 1..3, into: "", do: <<Enum.random(?A..?Z)>>
  end

  @spec generate_game_id(String.t()) :: String.t()
  defp generate_game_id(game_code) when is_binary(game_code) do
    hash =
      game_code
      |> :erlang.phash2()
      |> :erlang.integer_to_binary()
      |> String.downcase()

    "game:#{hash}"
  end
end

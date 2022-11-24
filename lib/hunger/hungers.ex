defmodule Hunger.Hungers do
  Hunger.MatchManager

  @moduledoc """
  The Hungers context.
  """

  alias Hunger.MatchManager

  @doc """
  Returns the list of game.

  ## Examples

      iex> list_game()
      [%Game{}, ...]

  """
  def list_game do
    MatchManager.match_list()
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(match_name), do: MatchManager.match_status(match_name)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(name \\ nil) do
    name =
      case name do
        nil ->
          Nanoid.generate()

        val ->
          val
      end

    MatchManager.new_match(name)
  end

  def join_game(game) do
    MatchManager.join_match(game)
  end

  def submit(game, token, action) do
    MatchManager.submit_round(game, token, action)
  end

  def start_game(game) do
    MatchManager.start_match(game)
  end
end

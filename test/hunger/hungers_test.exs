defmodule Hunger.HungersTest do
  use Hunger.DataCase

  alias Hunger.Hungers

  describe "game" do
    alias Hunger.Hungers.Game

    import Hunger.HungersFixtures

    @invalid_attrs %{name: nil}

    test "list_game/0 returns all game" do
      game = game_fixture()
      assert Hungers.list_game() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Hungers.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Game{} = game} = Hungers.create_game(valid_attrs)
      assert game.name == "some name"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Hungers.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Game{} = game} = Hungers.update_game(game, update_attrs)
      assert game.name == "some updated name"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Hungers.update_game(game, @invalid_attrs)
      assert game == Hungers.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Hungers.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Hungers.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Hungers.change_game(game)
    end
  end
end

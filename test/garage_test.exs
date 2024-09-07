defmodule GarageTest do
  use ExUnit.Case
  doctest Garage

  test "greets the world" do
    assert Garage.hello() == :world
  end
end

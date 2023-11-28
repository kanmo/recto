defmodule RectoTest do
  use ExUnit.Case
  doctest Recto

  test "greets the world" do
    assert Recto.hello() == :world
  end
end

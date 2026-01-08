defmodule FunctionalDesignPart5Test do
  use ExUnit.Case
  doctest FunctionalDesignPart5

  test "greets the world" do
    assert FunctionalDesignPart5.hello() == :world
  end
end

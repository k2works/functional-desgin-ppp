defmodule FunctionalDesignPart2Test do
  use ExUnit.Case
  doctest FunctionalDesignPart2

  test "greets the world" do
    assert FunctionalDesignPart2.hello() == :world
  end
end

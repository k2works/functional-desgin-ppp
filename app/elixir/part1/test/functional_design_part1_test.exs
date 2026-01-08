defmodule FunctionalDesignPart1Test do
  use ExUnit.Case
  doctest FunctionalDesignPart1

  test "greets the world" do
    assert FunctionalDesignPart1.hello() == :world
  end
end

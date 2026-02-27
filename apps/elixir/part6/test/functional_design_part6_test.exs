defmodule FunctionalDesignPart6Test do
  use ExUnit.Case
  doctest FunctionalDesignPart6

  test "greets the world" do
    assert FunctionalDesignPart6.hello() == :world
  end
end

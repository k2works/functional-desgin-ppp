defmodule FunctionalDesignPart7Test do
  use ExUnit.Case
  doctest FunctionalDesignPart7

  test "greets the world" do
    assert FunctionalDesignPart7.hello() == :world
  end
end

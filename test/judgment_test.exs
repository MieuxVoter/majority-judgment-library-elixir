defmodule JudgmentTest do
  use ExUnit.Case
  doctest Judgment

  test "greets the world" do
    assert Judgment.hello() == :world
  end
end

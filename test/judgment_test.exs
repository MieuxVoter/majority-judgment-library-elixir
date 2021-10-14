defmodule JudgmentTest do
  use ExUnit.Case
  doctest Judgment

  test "Resolve Majority Judgment" do
    tallies = [
      [0, 1, 2, 3, 4],
      [0, 2, 1, 3, 4],
      [2, 1, 0, 3, 4],
    ]
    result = Judgment.Majority.resolve(tallies)
    assert result != nil
    assert result.proposals != nil
    assert length(result.proposals) == length(tallies)
    assert (for p <- result.proposals, do: p.index) == [0, 1, 2]
    assert (for p <- result.proposals, do: p.rank) == [1, 2, 3]
  end
end

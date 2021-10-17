defmodule JudgmentTest do
  use ExUnit.Case
  doctest Judgment

#  test "WTF is IO.inspect doing?" do
#    [13, 13, 13, 13, 13]
#      |> IO.inspect(label: "WTF with lucky 13")
#    # > '\r\r\r\r\r'
#    # Yeah… right.
#
#    for i <- 0..20 do
#      [i, i, i, i, i]
#      |> IO.inspect(label: "WTF with #{i}")
#    end
#  end

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
    assert (for p <- result.sortedProposals, do: p.index) == [0, 1, 2]
    assert (for p <- result.sortedProposals, do: p.rank) == [1, 2, 3]
  end

  test "MJ with equalities" do
    tallies = [
      [0, 1, 0, 3, 6],
      [0, 1, 2, 3, 4],
      [0, 1, 0, 3, 6],
      [0, 1, 0, 3, 6],
    ]
    result = Judgment.Majority.resolve(tallies)
    assert (for p <- result.proposals, do: p.index) == [0, 1, 2, 3]
    assert (for p <- result.proposals, do: p.rank) == [1, 4, 1, 1]
    assert (for p <- result.sortedProposals, do: p.index) == [0, 2, 3, 1]
    assert (for p <- result.sortedProposals, do: p.rank) == [1, 1, 1, 4]
  end

  test "MJ with multiple equalities" do
    tallies = [
      [1, 2, 3],
      [3, 2, 1],
      [2, 1, 3],
      [1, 2, 3],
      [3, 2, 1],
      [2, 1, 3],
    ]
    result = Judgment.Majority.resolve(tallies)
    assert (for p <- result.proposals, do: p.index) == [0, 1, 2, 3, 4, 5]
    assert (for p <- result.proposals, do: p.rank) == [1, 5, 3, 1, 5, 3]
    assert (for p <- result.sortedProposals, do: p.index) == [0, 3, 2, 5, 1, 4]
    assert (for p <- result.sortedProposals, do: p.rank) == [1, 1, 3, 3, 5, 5]
  end
end

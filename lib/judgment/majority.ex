defmodule Judgment.Majority do
  @moduledoc """
  Majority Judgment is a poll deliberation method with many benefits.
  """

  @doc """
  Resolve a poll according to Majority Judgment,
  in order to get the rank of each proposal.

  Returns a Judgment.Majority.PollResult struct.

  ## Example

  Say you have two proposals and three grades:

      iex> r = Judgment.Majority.resolve([ [1, 2, 7], [2, 4, 4] ])
      iex> assert (for p <- r.proposals, do: p.rank) == [1, 2]

  """
  def resolve(pollTally) do

    analyses = pollTally
               |> Enum.map(fn proposalTally -> Judgment.Majority.Analysis.runOn(proposalTally) end)

    scores = pollTally
             |> Enum.map(fn proposalTally -> computeScore(proposalTally) end)
             |> Enum.with_index()
#             |> IO.inspect(label: "scores")

    sortedScores = scores
                   # Doing two reverse() is probably not the most efficient way
                   # We aim to keep the input order when there are equalities.
                   |> Enum.reverse()
                   |> Enum.sort_by(fn {s, _i} -> s end)
                   |> Enum.reverse()
                   |> Enum.with_index()
                   |> Enum.map(fn {{s, i}, is} -> {s, i, is} end)
    #                   |> IO.inspect(label: "sorted scores")

    proposals = sortedScores
                |> Enum.sort_by(fn {_s, i, _is} -> i end)
                |> Enum.map(
                     fn {score, index, sortedIndex} ->
                       amountOfEqualsAbove =
                         sortedScores
                         |> Enum.take_while(fn {_s, i, _is} -> i != index end)
                         |> Enum.filter(fn {s, _i, _is} -> s == score end)
                         |> Enum.count
                       #                         |> IO.inspect(label: "amountOfEqualsAbove")
                       rank = sortedIndex + 1 - amountOfEqualsAbove
                       %Judgment.Majority.ProposalResult {
                         rank: rank,
                         index: index,
                         score: score,
                         analysis: Enum.at(analyses, index),
                       }
                     end
                   )

    sortedProposals = proposals
                      # Double reverse again, please help me
                      |> Enum.reverse()
                      |> Enum.sort_by(fn p -> p.score end)
                      |> Enum.reverse()

    %Judgment.Majority.PollResult{
      proposals: proposals,
      sortedProposals: sortedProposals,
    }
  end

  defp computeScore(proposalTally) do
    computeScore(proposalTally, Enum.count(proposalTally))
  end

  defp computeScore(proposalTally, depth) do
    #    IO.inspect(proposalTally, label: "computeScore")
    inner_sep = '_'
    outer_sep = '/'
    analysis = Judgment.Majority.Analysis.runOn(proposalTally)
    amountOfGrades = length(proposalTally)
    amountOfDigitsForGrade = computeAmountOfDigits(amountOfGrades)
    amountOfParticipants = proposalTally
                           |> Enum.sum
    amountOfDigitsForAdhesion = computeAmountOfDigits(amountOfParticipants * 2)

    if depth > 0 do
      medianScore = analysis.medianGrade
                    |> Integer.to_string
                    |> String.pad_leading(amountOfDigitsForGrade, "0")
      adhesionScore = (analysis.secondGroupSize * analysis.secondGroupSign + amountOfParticipants)
                      |> Integer.to_string
                      |> String.pad_leading(amountOfDigitsForAdhesion, "0")

      "#{medianScore}#{inner_sep}#{adhesionScore}#{outer_sep}"
      <>
      computeScore(
        proposalTally
        |> regradeJudgments(analysis.medianGrade, analysis.secondGroupGrade),
        depth - 1
      )
    else
      ""
    end
  end

  defp computeAmountOfDigits(value) do
    length(Integer.digits(value, 10))
  end

  defp regradeJudgments(tally, fromGrade, intoGrade) do
    if fromGrade == intoGrade do
      tally
    else
      regradedAmount = Enum.at(tally, fromGrade)
      tally
      |> Enum.with_index()
      |> Enum.map(
           fn {gradeTally, index} ->
             case index do
               ^fromGrade -> 0
               ^intoGrade -> regradedAmount + gradeTally
               _ -> gradeTally
             end
           end
         )
      #      |> IO.inspect(label: "regraded")
    end
  end

end

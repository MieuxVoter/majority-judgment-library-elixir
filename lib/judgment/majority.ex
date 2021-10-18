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
  def resolve(poll_tally, options \\ []) do
    default = [
      favor_contestation: true,
      #      score_with_separators: true,
    ]
    options = Keyword.merge(default, options)

    analyses = poll_tally
               |> Enum.map(
                    fn proposal_tally ->
                      Judgment.Majority.Analysis.run_on(proposal_tally, options[:favor_contestation])
                    end
                  )

    scores = poll_tally
             |> Enum.map(fn proposal_tally -> compute_score(proposal_tally) end)
             |> Enum.with_index()

    sorted_scores = scores
                    # Doing two reverse() is perhaps not the most efficient way
                    # We aim to keep the input order when there are equalities.
                    |> Enum.reverse()
                    |> Enum.sort_by(fn {score, _index} -> score end)
                    |> Enum.reverse()
                    |> Enum.with_index()
      #            |> Enum.map(fn t -> Tuple.flatten(t) end)  # Tuple.flatten/1 is undefined
                    |> Enum.map(fn {{score, index}, sorted_index} -> {score, index, sorted_index} end)

    proposals = sorted_scores
                |> Enum.sort_by(fn {_score, index, _sorted_index} -> index end)
                |> Enum.map(
                     fn {score, index, sorted_index} ->
                       amount_equals_above =
                         sorted_scores
                         |> Enum.take_while(fn {_s, i, _si} -> i != index end)
                         |> Enum.filter(fn {s, _i, _si} -> s == score end)
                         |> Enum.count
                       rank = sorted_index + 1 - amount_equals_above
                       %Judgment.Majority.ProposalResult {
                         rank: rank,
                         index: index,
                         score: score,
                         analysis: Enum.at(analyses, index),
                       }
                     end
                   )

    sorted_proposals = proposals
                       # Double reverse again, please have mercy
                       |> Enum.reverse()
                       |> Enum.sort_by(fn p -> p.score end)
                       |> Enum.reverse()

    %Judgment.Majority.PollResult{
      proposals: proposals,
      sorted_proposals: sorted_proposals,
    }
  end

  defp compute_score(proposalTally, options \\ []) do
    default = [
      inner_sep: '_',
      outer_sep: '/',
    ]
    options = Keyword.merge(default, options)
    compute_score(proposalTally, options, Enum.count(proposalTally))
  end

  defp compute_score(proposal_tally, options, depth) do
    inner_sep = options[:inner_sepe] || '_'
    outer_sep = options[:outer_sep] || '/'
    analysis = Judgment.Majority.Analysis.run_on(proposal_tally)
    amount_of_grades = length(proposal_tally)
    amount_of_digits_for_grade = compute_amount_of_digits(amount_of_grades)
    amount_of_participants = proposal_tally
                             |> Enum.sum
    amount_of_digits_for_adhesion = compute_amount_of_digits(amount_of_participants * 2)

    if depth > 0 do
      medianScore = analysis.median_grade
                    |> Integer.to_string
                    |> String.pad_leading(amount_of_digits_for_grade, "0")
      adhesionScore = (analysis.second_group_size * analysis.second_group_sign + amount_of_participants)
                      |> Integer.to_string
                      |> String.pad_leading(amount_of_digits_for_adhesion, "0")

      "#{medianScore}#{inner_sep}#{adhesionScore}#{outer_sep}"
      <>
      compute_score(
        proposal_tally
        |> regrade_judgments(analysis.median_grade, analysis.second_group_grade),
        options,
        depth - 1
      )
    else
      ""
    end
  end

  defp compute_amount_of_digits(value) do
    length(Integer.digits(value, 10))
  end

  defp regrade_judgments(tally, from_grade, into_grade) do
    if from_grade == into_grade do
      tally
    else
      regraded_amount = Enum.at(tally, from_grade)
      tally
      |> Enum.with_index()
      |> Enum.map(
           fn {grade_tally, index} ->
             case index do
               ^from_grade -> 0
               ^into_grade -> regraded_amount + grade_tally
               _ -> grade_tally
             end
           end
         )
    end
  end

end

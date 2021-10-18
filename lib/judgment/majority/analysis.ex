defmodule Judgment.Majority.Analysis do
  @moduledoc """
  An analysis of the tally of a single proposal (its merit profile).
  This does not hold the score nor the rank and is used to compute the score.
  """
  defstruct [
    :median_grade,
    :second_group_grade,
    :second_group_size,
    :second_group_sign,
    :adhesion_group_grade,
    :adhesion_group_size,
    :contestation_group_grade,
    :contestation_group_size
  ]

  def run_on(proposal_tally) do
    run_on(proposal_tally, true)
  end

  @doc """
  Run the analysis on the provided proposal tally.
  Returns a Judgment.Majority.Analysis.
  This is like a factory, I guess?
  """
  def run_on(proposal_tally, favor_contestation) do
    amount_of_judgments =
      proposal_tally
      |> Enum.sum()

    median_threshold =
      if favor_contestation do
        amount_of_judgments - 1
      else
        amount_of_judgments
      end
      # euclidean
      |> div(2)

    cumul =
      proposal_tally
      |> Enum.scan(fn a, b -> a + b end)

    # |> Enum.scan(&(&1 + &2))  # less obvious equivalent

    merit =
      proposal_tally
      |> Enum.with_index()
      |> Enum.zip(
        # add start
        [0 | cumul]
        |> Enum.reverse()
        |> tl()
        |> Enum.reverse()
      )
      # add stop
      |> Enum.zip(cumul)
      |> Enum.map(fn {{{grade_tally, index}, start}, stop} ->
        {index, grade_tally, start, stop}
      end)
      |> Enum.map(fn {index, grade_tally, start, stop} ->
        if start < median_threshold && stop <= median_threshold do
          {index, grade_tally, start, stop, :contestation}
        else
          if start <= median_threshold && stop > median_threshold do
            {index, grade_tally, start, stop, :majority}
          else
            if start > median_threshold && stop > median_threshold do
              {index, grade_tally, start, stop, :adhesion}
            else
              {index, grade_tally, start, stop, :majority}
            end
          end
        end
      end)

    median_grade =
      merit
      |> filter_by_type(:majority)
      |> Enum.map(fn {index, _grade_tally, _start, _stop, _type} ->
        index
      end)
      |> hd()

    contestationGroup =
      merit
      |> filter_by_type(:contestation)

    adhesionGroup =
      merit
      |> filter_by_type(:adhesion)

    contestation_group_size =
      contestationGroup
      |> sum()

    adhesion_group_size =
      adhesionGroup
      |> sum()

    contestation_group_grade =
      contestationGroup
      |> keep_only_with_grades
      |> fetch_index
      |> Enum.reverse()
      |> List.first()
      |> default(0)

    adhesion_group_grade =
      adhesionGroup
      |> keep_only_with_grades
      |> fetch_index
      |> List.first()
      |> default(0)

    contestation_is_biggest =
      if favor_contestation do
        contestation_group_size >= adhesion_group_size
      else
        contestation_group_size > adhesion_group_size
      end

    second_group_grade =
      if contestation_is_biggest do
        contestation_group_grade
      else
        adhesion_group_grade
      end

    second_group_size =
      if contestation_is_biggest do
        contestation_group_size
      else
        adhesion_group_size
      end

    second_group_sign =
      if contestation_is_biggest do
        -1
      else
        1
      end

    %Judgment.Majority.Analysis{
      median_grade: median_grade,
      second_group_grade: second_group_grade,
      second_group_size: second_group_size,
      second_group_sign: second_group_sign,
      adhesion_group_grade: adhesion_group_grade,
      adhesion_group_size: adhesion_group_size,
      contestation_group_grade: contestation_group_grade,
      contestation_group_size: contestation_group_size
    }
  end

  defp filter_by_type(merit, discriminator) do
    merit
    |> Enum.filter(fn {_index, _grade_tally, _start, _stop, type} ->
      type == discriminator
    end)
  end

  defp keep_only_with_grades(merit) do
    merit
    |> Enum.filter(fn {_index, grade_tally, _start, _stop, _type} ->
      grade_tally > 0
    end)
  end

  defp sum(merit) do
    merit
    |> Enum.map(fn {_index, grade_tally, _start, _stop, _type} ->
      grade_tally
    end)
    |> Enum.sum()
  end

  defp fetch_index(merit) do
    merit
    |> Enum.map(fn {index, _grade_tally, _start, _stop, _type} ->
      index
    end)
  end

  defp default(value, default) do
    if nil != value do
      value
    else
      default
    end
  end
end

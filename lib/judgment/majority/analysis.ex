defmodule Judgment.Majority.Analysis do
  @moduledoc """
  An analysis of the tally of a single proposal (its merit profile).
  """
  defstruct [
    :medianGrade,
    :secondGroupGrade,
    :secondGroupSize,
    :secondGroupSign,
    :adhesionGroupGrade,
    :adhesionGroupSize,
    :contestationGroupGrade,
    :contestationGroupSize,
  ]

  def runOn(proposalTally) do
    IO.inspect(proposalTally, label: "Running analysis on")

    favorContestation = true

    amountOfJudgments = proposalTally |> Enum.sum()

    medianThreshold =
      if favorContestation do
        amountOfJudgments - 1
      else
        amountOfJudgments
      end
      |> div(2)

    cumul =
      proposalTally
      |> Enum.scan(fn (a, b) -> a + b end)
#      |> Enum.scan(&(&1 + &2))  # less obvious equivalent
#      |> IO.inspect(label: "cumul")

    merit =
      proposalTally
      |> Enum.with_index()
      |> Enum.zip(
           [0 | cumul]
           |> Enum.reverse()
           |> tl()
           |> Enum.reverse()
         )
      |> Enum.zip(cumul)
      |> Enum.map(
           fn {{{gradeTally, index}, start}, stop} ->
             {index, gradeTally, start, stop}
           end
         )
      |> Enum.map(
           fn {index, gradeTally, start, stop} ->
             if start < medianThreshold && stop <= medianThreshold do
               {index, gradeTally, start, stop, :contestation}
             else
               if start <= medianThreshold && stop > medianThreshold do
                 {index, gradeTally, start, stop, :majority}
               else
                 if start > medianThreshold && stop > medianThreshold do
                   {index, gradeTally, start, stop, :adhesion}
                 else
                   {index, gradeTally, start, stop, :majority}
                 end
               end
             end
           end
         )
      |> IO.inspect(label: "merit")

    medianGrade =
      merit
      |> filterByType(:majority)
      |> Enum.map(
           fn {index, _gradeTally, _start, _stop, _type} ->
             index
           end
         )
      |> hd()
      |> IO.inspect(label: "medianGrade")

    contestationGroup = merit |> filterByType(:contestation)
    adhesionGroup = merit |> filterByType(:adhesion)

    contestationGroupSize = contestationGroup |> sum()
      |> IO.inspect(label: "contestation")

    contestationGroupGrade =
      contestationGroup
      |> filterOnlyWithGrades()
      |> fetchIndex()
      |> Enum.reverse()
      |> List.first()
      |> default(0)
      |> IO.inspect(label: "contestationGroupGrade")

    adhesionGroupGrade =
      adhesionGroup
      |> filterOnlyWithGrades()
      |> fetchIndex()
      |> List.first()
      |> default(0)
      |> IO.inspect(label: "adhesionGroupGrade")

    adhesionGroupSize = adhesionGroup |> sum()
      |> IO.inspect(label: "adhesion")

    contestationIsBiggest = if favorContestation do
      contestationGroupSize >= adhesionGroupSize
    else
      contestationGroupSize > adhesionGroupSize
    end

    secondGroupGrade = if contestationIsBiggest do contestationGroupGrade else adhesionGroupGrade end
    secondGroupSize = if contestationIsBiggest do contestationGroupSize else adhesionGroupSize end
    secondGroupSign = if contestationIsBiggest do -1 else 1 end

    %Judgment.Majority.Analysis {
      medianGrade: medianGrade,
      secondGroupGrade: secondGroupGrade,
      secondGroupSize: secondGroupSize,
      secondGroupSign: secondGroupSign,
      adhesionGroupGrade: adhesionGroupGrade,
      adhesionGroupSize: adhesionGroupSize,
      contestationGroupGrade: contestationGroupGrade,
      contestationGroupSize: contestationGroupSize,
    }
  end

  defp filterByType(merit, discriminator) do
    merit
    |> Enum.filter(
         fn {_index, _gradeTally, _start, _stop, type} ->
           type == discriminator
         end
       )
  end

  def filterOnlyWithGrades(merit) do
    merit
    |> Enum.filter(
         fn {_index, gradeTally, _start, _stop, _type} ->
           gradeTally > 0
         end
       )
  end

#  defp sumByType(merit, discriminator) do
#    merit
#    |> filterByType(discriminator)
#    |> Enum.map(
#         fn {_index, gradeTally, _start, _stop, _type} ->
#           gradeTally
#         end
#       )
#    |> Enum.sum()
#  end

  defp sum(merit) do
    merit
    |> Enum.map(
         fn {_index, gradeTally, _start, _stop, _type} ->
           gradeTally
         end
       )
    |> Enum.sum()
  end

  defp fetchIndex(merit) do
    merit
    |> Enum.map(
         fn {index, _gradeTally, _start, _stop, _type} ->
           index
         end
       )
  end

  defp default(value, default) do
    if nil != value do
      value
    else
      default
    end
  end
end

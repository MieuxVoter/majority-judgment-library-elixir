defmodule Judgment.Majority.PollResult do
  @moduledoc """
  Results of a single Poll.
  """
  defstruct [
    :proposals,
    :sortedProposals,
    # etc.
  ]
end

defmodule Judgment.Majority.ProposalResult do
  @moduledoc """
  Results of a single Proposal.
  """
  defstruct [
    :index,
    :rank,
    :score,
    :analysis,
  ]
end

defmodule Judgment.Majority.PollResult do
  @moduledoc """
  Results of a single Poll.
  """
  defstruct [
    :proposals,
    :sorted_proposals
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
    :analysis
  ]
end

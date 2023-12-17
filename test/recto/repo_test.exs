defmodule Recto.RepoTest do
  use ExUnit.Case

  require Recto.TestRepo, as: TestRepo

  @moduletag :capture_log


  test "defines child_spec/1" do
    assert TestRepo.child_spec([]) == %{
             id: TestRepo,
             start: {TestRepo, :start_link, [[]]},
             type: :supervisor
           }
  end

end

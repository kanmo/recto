defmodule Recto.RepoTest do
  use ExUnit.Case

  require Recto.TestRepo, as: TestRepo

  @moduletag :capture_log

  defmodule MySchema do
    use Recto.Schema

    schema "my_schema" do
      field :x, :string
      field :y, :binary
      field :array, {:array, :string}
      field :map, {:map, :string}
    end
  end

  test "defines child_spec/1" do
    assert TestRepo.child_spec([]) == %{
             id: TestRepo,
             start: {TestRepo, :start_link, [[]]},
             type: :supervisor
           }
  end

  describe "get" do
    test "raises on bad inputs" do
      TestRepo.get(MySchema, 123)

      message = "cannot perform Ecto.Repo.get/2 because the given value is nil"

      assert_raise ArgumentError, message, fn ->
        TestRepo.get(MySchema, nil)
      end
    end
  end

end

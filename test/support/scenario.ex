defmodule Aurora.UixWeb.Test.Scenario do
  @moduledoc """
  Runs one scenario on every backend of the mirrored fixture.

  ## Key Features

  - Lists the backends a scenario runs on, each with the slug its routes carry
  - Runs a scenario body once per backend, starting each run from an empty mirror fixture
  - Names the backend in the message of a failed assertion
  - Builds the path of a mirror route from its backend, variant and source

  ## Key Constraints

  - Only for test scenarios
  - No function is named after a `Phoenix.VerifiedRoutes` export, which `ConnCase` imports
  """

  alias Aurora.Uix.Test.Mirror.Seeds

  @type backend :: %{name: :ash | :ctx, slug: binary()}

  @doc """
  Returns the backends a scenario runs on, in run order.

  ## Returns
  list(backend()) - The Ash and the Ecto backend.
  """
  @spec backends() :: [backend()]
  def backends, do: [%{name: :ash, slug: "ash"}, %{name: :ctx, slug: "ctx"}]

  @doc """
  Runs `fun` once for each backend whose name is in `names`, in the order of `backends/0`.

  Every mirror row is deleted before each run. An `ExUnit.AssertionError` raised by `fun` is
  re-raised with the backend name prepended to its message.

  ## Parameters
  - `names` (list(:ash | :ctx)) - The backends to run on.
  - `fun` ((backend() -> any())) - The scenario body.

  ## Returns
  :ok
  """
  @spec each_backend([:ash | :ctx], (backend() -> any())) :: :ok
  def each_backend(names \\ [:ash, :ctx], fun) do
    backends()
    |> Enum.filter(&(&1.name in names))
    |> Enum.each(&run_backend(&1, fun))
  end

  @doc """
  Returns the path of a mirror route.

  ## Parameters
  - `backend` (backend()) - The backend of the route.
  - `variant` (binary()) - The slug of the views variant.
  - `source` (binary()) - The source of the resource.
  - `suffix` (binary()) - Appended to the path, such as `"/new"`.

  ## Returns
  binary() - The path, in the form `/mirror-<backend>-<variant>-<source><suffix>`.
  """
  @spec mirror_path(backend(), binary(), binary(), binary()) :: binary()
  def mirror_path(backend, variant, source, suffix \\ ""),
    do: "/mirror-#{backend.slug}-#{variant}-#{source}#{suffix}"

  ## PRIVATE ##

  @spec run_backend(backend(), (backend() -> any())) :: any()
  defp run_backend(backend, fun) do
    Seeds.delete_all_mirror_data()

    try do
      fun.(backend)
    rescue
      error in ExUnit.AssertionError ->
        reraise %{error | message: "[backend: #{backend.name}] #{error.message}"},
                __STACKTRACE__
    end
  end
end

defmodule BnzFx.Application do
  @moduledoc """
  The BnzFx Application Service.

  The lsp system business domain lives in this application.

  Exposes API to clients such as the `BnzFxWeb` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {ConCache, [name: :bnz_fx, ttl_check_interval: false]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: BnzFx.Supervisor)
  end
end


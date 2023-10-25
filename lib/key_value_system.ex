defmodule KeyValue.System do
  def start_link do
    Supervisor.start_link([KeyValue.ProcessRegistry, KeyValue.Cache, KeyValue.Web],
      strategy: :one_for_one
    )
  end
end

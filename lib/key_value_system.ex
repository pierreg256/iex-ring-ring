defmodule KeyValue.System do
  def start_link do
    Supervisor.start_link(
      [
        {Cluster.Supervisor,
         [Application.get_env(:libcluster, :topologies), [name: SwarmTest.ClusterSupervisor]]},
        KeyValue.ProcessRegistry,
        KeyValue.Cache,
        KeyValue.Web
      ],
      strategy: :one_for_one
    )
  end
end

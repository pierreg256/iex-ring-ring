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

  def load do
    for _ <- 1..1000 do
      key = :crypto.strong_rand_bytes(8) |> Base.encode64()
      value = :crypto.strong_rand_bytes(8) |> Base.encode64()
      KeyValue.Cache.put(key, value)
    end
  end

  def status do
    Swarm.registered()
    |> Enum.map(fn {name, _pid} -> {name, Swarm.whereis_name(name)} end)
  end
end

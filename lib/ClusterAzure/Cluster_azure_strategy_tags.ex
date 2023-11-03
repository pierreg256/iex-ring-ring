defmodule ClusterAzure.Strategy.Tags do
  @moduledoc """
  This clustering strategy works by loading all instances that have the given
  tag associated with them.

  All instances must be started with the same app name and have security groups
  configured to allow inter-node communication.

      config :libcluster,
        topologies: [
          tags_example: [
            strategy: #{__MODULE__},
            config: [
              tagname: "mytag",
              tagvalue: "tagvalue",
              app_prefix: "app",
              dns_suffix: "ring.demo",
              polling_interval: 10_000]]],
              show_debug: false

  ## Configuration Options

  | Key | Required | Description |
  | --- | -------- | ----------- |
  | `:tagname` | yes | Name of the Azure VM tag to look for. |
  | `:tagvalue` | yes | Can be passed a static value (string), a 0-arity function, or a 1-arity function (which will be passed the value of `:ec2_tagname` at invocation). |
  | `:app_prefix` | no | Will be prepended to the node's dns suffix to create the node name. |
  | `:dns_suffix` | yes | dsn suffix to resolve node address |
  | `:polling_interval` | no | Number of milliseconds to wait between polls to the EC2 api. Defaults to 5_000 |
  | `:show_debug` | no | True or false, whether or not to show the debug log. Defaults to true |
  """
  use GenServer
  use Cluster.Strategy
  import Cluster.Logger
  alias Cluster.Strategy.State

  @default_polling_interval 5_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # libcluster ~> 3.0
  @impl GenServer
  def init([%State{} = state]) do
    state = state |> Map.put(:meta, MapSet.new())

    {:ok, load(state)}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    handle_info(:load, state)
  end

  def handle_info(:load, %State{} = state) do
    {:noreply, load(state)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def join(node, state) do
    # Implement the join function here
    IO.puts("Joining #{inspect(node)}")
    {:ok, state}
  end

  def alive(node, state) do
    # Implement the alive function here
    IO.puts("Alive #{inspect(node)}")
    {:ok, state}
  end

  def get_nodes(%State{topology: topology, config: config}) do
    # Implement the get_nodes function here
    tag_name = Keyword.fetch!(config, :tagname)

    tag_value = Keyword.get(config, :tagvalue)

    app_prefix = Keyword.get(config, :app_prefix, "app")
    dns_suffix = Keyword.fetch!(config, :dns_suffix)

    cond do
      tag_name != nil and tag_value != nil and app_prefix != nil and dns_suffix != nil ->
        # simulate a call to the Azure registry
        response = "[
          {
            \"name\": \"node-communal-vulture\"
          },
          {
            \"name\": \"node-native-boa\"
          }
        ]" |> Poison.decode!()

        {:ok,
         response
         |> Enum.map(fn x -> String.to_atom(x["name"] <> "@" <> dns_suffix) end)
         |> MapSet.new()}

      tag_name == nil ->
        warn(topology, "azure tags strategy is selected, but :tagname is not configured!")
        {:error, []}

      tag_value == nil ->
        warn(topology, "azure tags strategy is selected, but :tagvalue is not configured!")
        {:error, []}

      dns_suffix == nil ->
        warn(topology, "azure tags strategy is selected, but :dns_suffix is not configured!")
        {:error, []}

      :else ->
        warn(topology, "azure tags strategy is selected, but is not configured!")
        {:error, []}
    end
  end

  defp load(
         %State{
           topology: topology,
           connect: connect,
           disconnect: disconnect,
           list_nodes: list_nodes
         } = state
       ) do
    # Implement the load function here
    IO.puts("Loading Azure topology...")

    case(get_nodes(state)) do
      {:ok, new_nodelist} ->
        removed = MapSet.difference(state.meta, new_nodelist)

        new_nodelist =
          case Cluster.Strategy.disconnect_nodes(
                 topology,
                 disconnect,
                 list_nodes,
                 MapSet.to_list(removed)
               ) do
            :ok ->
              new_nodelist

            {:error, bad_nodes} ->
              # Add back the nodes which should have been removed, but which couldn't be for some reason
              Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
                MapSet.put(acc, n)
              end)

            _ ->
              IO.puts("Error disconnecting nodes")
          end

        new_nodelist =
          case Cluster.Strategy.connect_nodes(
                 topology,
                 connect,
                 list_nodes,
                 MapSet.to_list(new_nodelist)
               ) do
            :ok ->
              new_nodelist

            {:error, bad_nodes} ->
              # Remove the nodes which should have been added, but couldn't be for some reason
              Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
                MapSet.delete(acc, n)
              end)

            _ ->
              IO.puts("Error connecting nodes")
          end

        Process.send_after(
          self(),
          :load,
          Keyword.get(state.config, :polling_interval, @default_polling_interval)
        )

        %{state | :meta => new_nodelist}

      _ ->
        Process.send_after(
          self(),
          :load,
          Keyword.get(state.config, :polling_interval, @default_polling_interval)
        )

        state
    end
  end
end

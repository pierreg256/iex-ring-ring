defmodule KeyValue.Cache do
  use Supervisor

  @shards 16

  def start_link(_) do
    IO.puts("Starting KV Cache")
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def init(_state) do
    IO.puts("KV Cache init")
    Supervisor.init([KeyValue.Server], strategy: :one_for_one)
  end

  def get(key) do
    name = "partition_#{shard_number(key)}"

    case Swarm.whereis_or_register_name(name, KeyValue.Cache, :register, [name]) do
      {:ok, pid} ->
        GenServer.call(pid, {:get, key})

      {:error, reason} ->
        {:error, reason}
    end
  end

  def put(key, value) do
    name = "partition_#{shard_number(key)}"

    case Swarm.whereis_or_register_name(name, KeyValue.Cache, :register, [name]) do
      {:ok, pid} ->
        GenServer.cast(pid, {:put, key, value})

      {:error, reason} ->
        {:error, reason}
    end
  end

  # def server_shard(key) do
  #   case start_child(key) do
  #     {:ok, _server} ->
  #       shard_number(key)

  #     {:error, {:already_started, _pid}} ->
  #       shard_number(key)
  #   end
  # end

  # def child_spec(_arg) do
  #   %{id: __MODULE__, start: {__MODULE__, :start_link, []}, type: :supervisor}
  # end

  def register(name) do
    IO.puts("Registering KV Server #{inspect(name)}")
    DynamicSupervisor.start_child(__MODULE__, {KeyValue.Server, [name]})
  end

  def shard_number(key) do
    :erlang.phash2(key, @shards)
  end
end

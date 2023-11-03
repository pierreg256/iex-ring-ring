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

  def size() do
    Swarm.registered() |> Enum.map(&Swarm.whereis_name(&1))

    # |> Enum.sum()
  end

  def register(name) do
    IO.puts("Registering KV Server #{inspect(name)}")
    DynamicSupervisor.start_child(__MODULE__, {KeyValue.Server, [name]})
  end

  def shard_number(key) do
    :erlang.phash2(key, @shards)
    |> Integer.to_string()
    |> String.pad_leading(3, "0")
  end
end

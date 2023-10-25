defmodule KeyValue.Cache do
  @shards 16

  def start_link() do
    IO.puts("Starting KV Cache")
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def init(_state) do
    {:ok, %{}}
  end

  def server_shard(key) do
    case start_child(key) do
      {:ok, _server} ->
        shard_number(key)

      {:error, {:already_started, _pid}} ->
        shard_number(key)
    end
  end

  def child_spec(_arg) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, type: :supervisor}
  end

  defp start_child(key) do
    DynamicSupervisor.start_child(__MODULE__, {KeyValue.Server, shard_number(key)})
  end

  def shard_number(key) do
    :erlang.phash2(key, @shards)
  end
end

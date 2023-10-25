defmodule KeyValue.Server do
  use GenServer, restart: :temporary

  def start_link(server_id) do
    # IO.puts("Starting KV Server for shard: #{server_id}")
    GenServer.start_link(__MODULE__, server_id, name: via_tuple(server_id))
  end

  defp via_tuple(server_id) do
    KeyValue.ProcessRegistry.via_tuple({__MODULE__, server_id})
  end

  def init(state) do
    IO.puts("KV Server init #{inspect(state)}")
    {:ok, %{shard: state, data: %{}}}
  end

  def get(key) do
    GenServer.call(via_tuple(KeyValue.Cache.server_shard(key)), {:get, key})
  end

  def put(key, value) do
    GenServer.cast(via_tuple(KeyValue.Cache.server_shard(key)), {:put, key, value})
  end

  def handle_call({:get, key}, _from, state) do
    value = Map.get(state.data, key)
    {:reply, value, state}
  end

  def handle_cast({:put, key, value}, state) do
    new_data = Map.put(state.data, key, value)
    {:noreply, %{state | data: new_data}}
  end
end

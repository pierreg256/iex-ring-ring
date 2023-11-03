defmodule KeyValue.Server do
  use GenServer, restart: :temporary

  def start_link([server_id]) do
    # IO.puts("Starting KV Server for shard: #{server_id}")
    GenServer.start_link(__MODULE__, [server_id])
  end

  def init([server_id]) do
    IO.puts("KV Server init #{inspect(server_id)}")
    {:ok, %{shard: server_id, data: %{}, size: 0}}
  end

  def handle_call({:get, :size}, _from, state) do
    {:reply, state.size, state}
  end

  def handle_call({:get, key}, _from, state) do
    value = Map.get(state.data, key)
    {:reply, value, state}
  end

  # called when a handoff has been initiated due to changes
  # in cluster topology, valid response values are:
  #
  #   - `:restart`, to simply restart the process on the new node
  #   - `{:resume, state}`, to hand off some state to the new process
  #   - `:ignore`, to leave the process running on its current node
  #
  def handle_call({:swarm, :begin_handoff}, _from, state) do
    IO.puts("j'envoie mon état avant de mourir #{inspect(state)}")
    {:reply, {:resume, state}, state}
  end

  def handle_cast({:put, key, value}, state) do
    new_data = Map.put(state.data, key, value)
    {:noreply, %{state | data: new_data, size: Kernel.map_size(new_data)}}
  end

  # called after the process has been restarted on its new node,
  # and the old process' state is being handed off. This is only
  # sent if the return to `begin_handoff` was `{:resume, state}`.
  # **NOTE**: This is called *after* the process is successfully started,
  # so make sure to design your processes around this caveat if you
  # wish to hand off state like this.
  def handle_cast({:swarm, :end_handoff, state}, _empty) do
    {:noreply, state}
  end

  # called when a network split is healed and the local process
  # should continue running, but a duplicate process on the other
  # side of the split is handing off its state to us. You can choose
  # to ignore the handoff state, or apply your own conflict resolution
  # strategy
  def handle_cast({:swarm, :resolve_conflict, _delay}, state) do
    {:noreply, state}
  end

  # this message is sent when this process should die
  # because it is being moved, use this as an opportunity
  # to clean up
  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end
end

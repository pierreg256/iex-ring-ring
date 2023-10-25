defmodule KeyValueTest do
  use ExUnit.Case
  doctest KeyValue.Server

  test "KV server" do
    :ok = KeyValue.Server.put(:hello, :world)
    value = KeyValue.Server.get(:hello)

    assert value == :world
  end
end

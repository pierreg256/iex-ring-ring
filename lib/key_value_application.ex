defmodule KeyValue.Application do
  use Application

  def start(_, _) do
    IO.puts("Starting KV Application")
    KeyValue.System.start_link()
  end
end

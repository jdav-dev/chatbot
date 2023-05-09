defmodule Chatbot.Config do
  @moduledoc """
  Persistent key-value store for runtime config.
  """
  use GenServer

  @table :chatbot_config

  @filename :chatbot
            |> :code.priv_dir()
            |> Path.join("#{@table}.ets")
            |> to_charlist()

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl GenServer
  def init(_init_arg) do
    with {:error, _reason} <- :ets.file2tab(@filename, verify: true),
         table <- :ets.new(@table, [:named_table, read_concurrency: true]),
         :ok <- @filename |> Path.dirname() |> File.mkdir_p(),
         :ok <- save_to_disk(table) do
      {:ok, table}
    else
      {:ok, table} -> {:ok, table}
      error -> {:stop, error}
    end
  end

  defp save_to_disk(table) do
    :ets.tab2file(table, @filename, extended_info: [:object_count, :md5sum], sync: true)
  end

  def all do
    @table
    |> :ets.tab2list()
    |> Enum.sort()
  end

  def get(key, default \\ nil) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> value
      _ -> GenServer.call(__MODULE__, {:put, key, default})
    end
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @impl GenServer
  def handle_call({:put, key, value}, _from, table) do
    :ets.insert(table, {key, value})

    case save_to_disk(table) do
      :ok -> {:reply, value, table}
      error -> {:stop, error, table}
    end
  end
end

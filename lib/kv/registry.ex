defmodule KV.Registry do
  use GenServer

  ## Client API
  # def start_link(event_manager, buckets, opts \\ []) do
  #  # 1. start_link now expects the event manager as argument
  #  # 1. Pass the buckets supervisor as argument
  #  GenServer.start_link(__MODULE__, {event_manager, buckets}, opts)
  # end
  @doc """
  Starts the registry.
  """
  def start_link(table, event_manager, buckets, opts \\ []) do
    # 1. We now expect the table as argument and pass it to the server
    GenServer.start_link(__MODULE__, {table, event_manager, buckets}, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.
  Returns `{:ok, pid}` in case a bucket exists, `:error` otherwise.
  """
  # def lookup(server, name) do
  #  GenServer.call(server, {:lookup, name})
  # end

  def lookup(table, name) do
    # 2. lookup now expects a table and looks directly into ETS
    #    No request is sent to the server
    case :ets.lookup(table, name) do
      [{^name, bucket}] -> 
        {:ok, bucket}
      [] -> 
        :error
    end
  end


  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Server callbacks

#  def init({events, buckets}) do
#    # 2. The init callback now receives the event manager.
#    #    We have also changed the manager state from a tuple
#    #    to a map, allowing us to add new fields in the future
#    #    without needing to rewrite all callbacks.
#    names = HashDict.new
#    refs  = HashDict.new
#    # 2. Store the buckets supervisor in the state
#    {:ok, %{names: names, refs: refs, events: events, buckets: buckets}}
#  end

  def init({table, events, buckets}) do
    ets = :ets.new(table, [:named_table, read_concurrency: true])
    refs = HashDict.new
    {:ok, %{names: ets, refs: refs, events: events, buckets: buckets}}
  end


#  def handle_call({:lookup, name}, _from, state) do
#    {:reply, HashDict.fetch(state.names, name), state}
#  end

#  def handle_cast({:create, name}, state) do
#    if HashDict.get(state.names, name) do
#      {:noreply, state}
#    else
#      # 3. Use the buckets supervisor instead of starting buckets directly
#      # {:ok, pid} = KV.Bucket.start_link()
#      {:ok, pid} = KV.Bucket.Supervisor.start_bucket(state.buckets)
#      ref = Process.monitor(pid)
#      refs = HashDict.put(state.refs, ref, name)
#      names = HashDict.put(state.names, name, pid)
#      # 3. Push a notification to the event manager on create
#      GenEvent.sync_notify(state.events, {:create, name, pid})
#      {:noreply, %{state | names: names, refs: refs}}
#    end
#  end

  def handle_cast({:create, name}, state) do
    # 5. Read and write to the ETS table instead of the HashDict
    case lookup(state.names, name) do
      {:ok, _pid} -> 
        {:noreply, state}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket(state.buckets)
        ref = Process.monitor(pid)
        refs = HashDict.put(state.refs, ref, name)
        :ets.insert(state.names, {name, pid})
        GenEvent.sync_notify(state.events, {:create, name, pid})
        {:noreply, %{state | refs: refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = HashDict.pop(state.refs, ref)
    :ets.delete(state.names, name)
    # names = HashDict.delete(state.names, name)
    # 4. Push a notification to the event manager on exit
    GenEvent.sync_notify(state.events, {:exit, name, pid})
    {:noreply, %{state | refs: refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

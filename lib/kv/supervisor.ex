defmodule KV.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @manager_name KV.EventManager
  @registry_name KV.Registry
  @ets_registry_name KV.Registry
  @bucket_sup_name KV.Bucket.Supervisor

  def init(:ok) do
    children = [
      worker(GenEvent, [[name: @manager_name]]),
      supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
      worker(KV.Registry, [@ets_registry_name, @manager_name, 
        @bucket_sup_name, [name: @registry_name]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end




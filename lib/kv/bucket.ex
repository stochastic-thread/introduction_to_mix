defmodule KV.Bucket do
  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, 
      fn dict -> HashDict.get(dict, key) 
    end)
  end

  @doc """
  Puts the value for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, 
      fn dict -> HashDict.put(dict, key, value)
    end)
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` has a corresponding value
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, 
      fn dict -> HashDict.pop(dict, key)
    end)
  end
end
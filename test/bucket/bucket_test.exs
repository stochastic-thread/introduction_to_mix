defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link
    {:ok, bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    {:ok, bucket} = KV.Bucket.start_link
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "deletes key, returns value", %{bucket: bucket} do
    {:ok, bucket} = KV.Bucket.start_link
    assert KV.Bucket.get(bucket, "milk") == nil
    KV.Bucket.put(bucket, "milk", 3)
    KV.Bucket.put(bucket, "oranges", 5)
    assert KV.Bucket.delete(bucket, "milk") == 3
    assert KV.Bucket.delete(bucket, "oranges") == 5
    assert KV.Bucket.get(bucket, "milk") == nil
    assert KV.Bucket.get(bucket, "oranges") == nil
  end
end
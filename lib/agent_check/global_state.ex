defmodule AgentCheck.GlobalState do
  use Agent

  defmodule State do
    defstruct state: "ready",
              capacity: "100",
              capacity_callback: nil,
              maint_callback: nil

  end

  def default_capacity() do
    "100"
  end

  def start_link(capacity_callback, maint_callback) do
    result = Agent.start_link(fn -> %AgentCheck.GlobalState.State{capacity_callback: capacity_callback, maint_callback: maint_callback} end, name: __MODULE__)
    :timer.apply_interval(10000, AgentCheck.GlobalState, :update_capacity_loop, [])
    
    result
  end

  @doc "Update the capacity and reschedule it every 10 seconds"
  def update_capacity_loop() do
    new_capacity = case get_key(:capacity_callback) do
      nil -> get_key(:capacity)
      {module, method} -> apply(module, method, [])
    end

    update_key(:capacity, new_capacity)

    :timer.apply_interval(10000, AgentCheck.GlobalState, :update_capacity_loop, [])
  end

  @doc "Set a new state"
  def set_state(new_state) do
    update_key(:state, new_state)
  end

  def down(), do: set_state("down")
  def drain(), do: set_state("drain")
  def ready(), do: set_state("ready")
  def stop(reason), do: set_state("stopped##{reason}")
  def up(), do: set_state("up")

  @doc "Call maint callback"
  def maint() do
    case get_key(:maint_callback) do
      nil -> nil
      {module, method} -> apply(module, method, [])
    end

    set_state("maint")
  end

  @doc "Get the entire state struct"
  def get_stats() do
    Agent.get(__MODULE__, fn (state) -> state end)
  end

  defp get_key(key) do
    Agent.get(__MODULE__, fn (state) -> Map.get(state, key) end)
  end

  defp update_key(key, value) do
    Agent.update(__MODULE__, fn (old_state) -> Map.put(old_state, key, value) end)
  end
end

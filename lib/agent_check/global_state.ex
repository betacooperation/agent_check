defmodule AgentCheck.GlobalState do
  @moduledoc """
  This Agent persists the gobal state of the appliction that is reported back to HaProxy.
  """
  use Agent

  @default_capacity 100
  @capacity_update_interval 10_000

  defmodule State do
    @moduledoc """
    The struct stat holds the agents' state.
    """
    defstruct state: "ready",
              # @default_capacity,
              capacity: 100,
              capacity_callback: nil,
              maint_callback: nil
  end

  @doc "Start the agent and schedule the first capacity update."
  def start_link(capacity_callback, maint_callback) do
    if capacity_callback, do: schedule_capacity_update()

    Agent.start_link(
      fn ->
        %AgentCheck.GlobalState.State{
          capacity_callback: capacity_callback,
          maint_callback: maint_callback
        }
      end,
      name: __MODULE__
    )
  end

  @doc "Update the capacity and reschedule it every 10 seconds"
  def update_capacity_loop() do
    {module, method} = get_key(:capacity_callback)
    capacity = apply(module, method, [])
    update_capacity(capacity)

    schedule_capacity_update()
  end

  def schedule_capacity_update(),
    do:
      :timer.apply_interval(
        @capacity_update_interval,
        AgentCheck.GlobalState,
        :update_capacity_loop,
        []
      )

  @doc "Update the capacity in the state struct"
  def update_capacity(new_capacity) when is_binary(new_capacity) do
    new_capacity
    |> Integer.parse()
    |> elem(0)
    |> update_capacity
  end

  def update_capacity(new_capacity) when is_number(new_capacity),
    do: update_key(:capacity, new_capacity)

  def update_capacity(_), do: update_capacity(@default_capacity)

  @doc "Set a new state"
  def set_state(new_state) do
    update_key(:state, new_state)
  end

  def down(), do: set_state("down")
  def drain(), do: set_state("drain")
  def ready(), do: set_state("ready")
  def stop(reason), do: set_state("stopped##{reason}")
  def up(), do: set_state("up")

  @doc "Call maint callback after 10 seconds"
  def maint() do
    set_state("maint")

    case get_key(:maint_callback) do
      nil -> nil
      {module, method} -> apply(module, method, [])
    end
  end

  @doc "Get the entire state struct"
  def get_stats() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  defp get_key(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key) end)
  end

  defp update_key(key, value) do
    Agent.update(__MODULE__, fn old_state -> Map.put(old_state, key, value) end)
  end
end

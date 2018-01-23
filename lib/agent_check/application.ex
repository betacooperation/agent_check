defmodule AgentCheck.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    port = Application.get_env(:agent_check, :port)
    capacity_callback = Application.get_env(:agent_check, :capacity_callback)
    maint_callback = Application.get_env(:agent_check, :maint_callback)

    children = [
      {Task.Supervisor, name: AgentCheck.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> AgentCheck.accept(port) end}, restart: :permanent),
      worker(AgentCheck.GlobalState, [capacity_callback, maint_callback])
    ]

    opts = [strategy: :one_for_one, name: AgentCheck.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

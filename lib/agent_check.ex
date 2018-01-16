defmodule AgentCheck do
  @moduledoc """
  Implementation of the Agent Check protocol for your Elixir/Phoenix app.
  Also see - https://cbonte.github.io/haproxy-dconv/1.8/configuration.html#5.2-agent-check

  It allows for easy rolling restarts and dynamic backpressure to your loadbalancer.
  """
  require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Agent Check - accepting connections on port #{port}"

    loop_acceptor(socket)
  end

  @doc """
  Wait for incomming socket connection (blocking) and spawn of a Task when one comes in.
  """
  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(AgentCheck.TaskSupervisor, fn -> serve(client) end)

    :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  def serve(socket) do
    reply = socket
            |> read_line()
            |> String.trim("\n")
            |> String.trim("\r")
            |> handle_command

    :gen_tcp.send(socket, "#{reply}\n")
    :gen_tcp.close(socket)
  end

  def handle_command(command) do
    case command do
      "state" -> AgentCheck.GlobalState.get_stats |> format_haproxy_state # Used by Haproxy
      "stats" -> inspect(AgentCheck.GlobalState.get_stats)
      "ready" -> AgentCheck.GlobalState.ready
      "maint" -> AgentCheck.GlobalState.maint
      "stop" -> AgentCheck.GlobalState.stop("migration")
      "drain" -> AgentCheck.GlobalState.drain
      "up" -> AgentCheck.GlobalState.up
      "down" -> AgentCheck.GlobalState.down
      _ -> "Unknown command"
    end
  end

  @doc """
  Reformat the stats struct into a haproxy state format.
  """
  def format_haproxy_state(stats_struct) do
    state = Map.get(stats_struct, :state)
    capacity = Map.get(stats_struct, :capacity)

    "#{state} #{capacity}"
  end

  def read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

end

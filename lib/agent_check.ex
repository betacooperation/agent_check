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
  def accept(port) when is_integer(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Agent Check - accepting connections on port #{port}")

    loop_acceptor(socket)
  end

  def accept(port) when is_binary(port) do
    port
    |> Integer.parse()
    |> elem(0)
    |> accept
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

  @doc """
  Connect the socket and wait for a command.
  """
  def serve(socket) do
    reply =
      socket
      |> read_line()
      |> String.trim("\n")
      |> String.trim("\r")
      |> handle_command

    :gen_tcp.send(socket, "#{reply}\n")
    :gen_tcp.close(socket)
  end

  @doc """
  Try to handle the received commandline.
  """
  def handle_command("state"), do: AgentCheck.GlobalState.get_stats() |> format_haproxy_state # Used by Haproxy
  def handle_command("stats"), do: inspect(AgentCheck.GlobalState.get_stats())
  def handle_command("ready"), do: AgentCheck.GlobalState.ready()
  def handle_command("maint"), do: AgentCheck.GlobalState.maint()
  def handle_command("stop"), do: AgentCheck.GlobalState.stop("reason")
  def handle_command("drain"), do: AgentCheck.GlobalState.drain()
  def handle_command("up"), do: AgentCheck.GlobalState.up()
  def handle_command("down"), do: AgentCheck.GlobalState.down()
  def handle_command(_), do: "Unknown command"

  @doc """
  Reformat the stats struct into a haproxy state format.
  """
  def format_haproxy_state(stats_struct) do
    state = Map.get(stats_struct, :state)
    capacity = Map.get(stats_struct, :capacity)

    "#{state} #{capacity}"
  end

  @doc """
  Read a single line from the connected socket.
  """
  def read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end
end

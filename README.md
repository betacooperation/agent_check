# Agent Check
HAProxy Agent Check protocol implementation for Elixir/Phoenix apps. Allows for easy rolling restarts and dynamic backpressure to your loadbalancer.

![screencast](https://github.com/betacooperation/agent_check/raw/master/doc/screencast.gif "Screencast")

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `agent_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agent_check, "~> 0.2.8"}
  ]
end

  def application do
    [
      extra_applications: [:logger, :agent_check],
      mod: {Your.Application, []}
    ]
  end
```

Then the following needs to be added to your config:

```elixir
  config :agent_check,
         port: System.get_env("AGENT_CHECK_PORT") || 6666,
         capacity_callback: {Your.Application, :calculate_capacity},
         maint_callback: {Your.Application, :close_all_open_connections}
```

The capacity callback *must* return a binary or integer between 1 and 100. Both callbacks are optional. 

Next you need to configure Haproxy to check for your agent.
```
backend your_backend_web
  mode tcp
  balance roundrobin
  server websrv1 192.168.1.101:443 weight 255 check agent-check agent-port 6666 agent-addr 192.168.1.101 agent-send state\n
  server websrv2 192.168.1.102:443 weight 255 check agent-check agent-port 6666 agent-addr 192.168.1.102 agent-send state\n
```

## Usage
To check if the agent is running correctly, connect to it via telnet:

```bash
$ telnet 192.168.0.101 6666 
Trying 192.168.0.101...
Connected to websrv1.
Escape character is '^]'.
state
ready 100
Connection closed by foreign host.
```

The following commands are available:

| Command | Description |
|---------|-------------|
| maint | Go to maintenance mode |
| ready | Return from maintenance mode to up state |
| state | Get server state and capacity information in HAProxy format |
| stats | Get server state and capacity information in raw format | 


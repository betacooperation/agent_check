defmodule AgentCheckTest do
  use ExUnit.Case
  doctest AgentCheck

  test "check if the agent starts" do
    assert AgentCheck.handle_command("state") == "ready 100"
  end
end

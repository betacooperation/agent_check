# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :agent_check,
   port: System.get_env("AGENT_CHECK_PORT") || 6666,
   capacity_callback: nil,
   maint_callback: nil


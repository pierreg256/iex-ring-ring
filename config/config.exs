import Config

config(:key_value, http_port: 4000)

config :swarm,
  node_whitelist: [~r/^kv-[\d]@.*$/],
  distribution_strategy: Swarm.Distribution.Ring

config :libcluster,
  topologies: [
    gossip: [
      strategy: Cluster.Strategy.Gossip
    ]
  ]

import_config "#{Mix.env()}.exs"

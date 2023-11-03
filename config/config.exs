import Config

config(:key_value, http_port: 4000)

config :swarm,
  # node_whitelist: [~r/^kv-[\d]@.*$/],
  distribution_strategy: Swarm.Distribution.Ring

config :libcluster,
  topologies: [
    # gossip: [
    #   strategy: Cluster.Strategy.Gossip
    # ],
    azure_tags: [
      strategy: ClusterAzure.Strategy.Tags,
      config: [
        tagname: "mytag",
        tagvalue: "tagvalue",
        app_prefix: "app",
        dns_suffix: "ring.demo",
        polling_interval: 3_000
      ]
    ]
  ]

import_config "#{Mix.env()}.exs"

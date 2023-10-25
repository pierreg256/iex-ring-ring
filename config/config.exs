use Mix.Config

config(:key_value, http_port: 4000)

import_config "#{Mix.env()}.exs"

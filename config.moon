config = require "lapis.config"

config "development", ->
  port 8080
  redis_addr "127.0.0.1"

config "production", ->
  port 80
  num_workers 4
  code_cache "on"
  redis_addr "redis"
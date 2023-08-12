job "vector" {
  datacenters = ["dc1"]

  group "vector" {

    task "vector" {
      driver = "docker"

      template {
        data        = var.vector_toml
        destination = "/local/vector.toml"
      }

      config {
        image = "timberio/vector:0.31.0-alpine"
        volumes = [
          "local/vector.toml:/etc/vector/vector.toml",
          "/var/run/docker.sock:/var/run/docker.sock",
        ]
      }

      resources {
        memory     = 100
        memory_max = 400
      }
    }
  }

  reschedule {
    attempts  = 1
    interval  = "24h"
    delay     = "10s"
    unlimited = false
  }

  update {
    auto_revert = true
  }
}

variable "vector_toml" {
  type    = string
  default = <<EOF
# https://vector.dev/docs/reference/configuration/

[api]
enabled = true

[sources.vector_logs]
type = "internal_logs"

[sinks.openobserve_vector_logs]
type = "http"
inputs = [ "vector_logs" ]
uri = "https://api.openobserve.ai/api/femiwiki_2lbGLNGsIgcwF9Y/vector_logs/_json"
method = "post"
auth.strategy = "basic"
auth.user = "admin@femiwiki.com"
auth.password = "OPENOBSERVE_PASSWORD"
compression = "gzip"
encoding.codec = "json"
encoding.timestamp_format = "rfc3339"
healthcheck.enabled = false

#
# Caddy log
#
[sources.caddy_logs]
type = "docker_logs"
include_containers = [ "http-" ]

[sinks.openobserve_caddy_logs]
type = "http"
inputs = [ "caddy_logs", ]
uri = "https://api.openobserve.ai/api/femiwiki_2lbGLNGsIgcwF9Y/caddy_logs/_json"
method = "post"
auth.strategy = "basic"
auth.user = "admin@femiwiki.com"
auth.password = "OPENOBSERVE_PASSWORD"
compression = "gzip"
encoding.codec = "json"
encoding.timestamp_format = "rfc3339"
healthcheck.enabled = false

#
# Other docker logs
#
[sources.docker_logs]
type = "docker_logs"
exclude_containers = [
  "http-",
]

[transforms.docker_parser]
inputs = [ "docker_logs" ]
type = "remap"
source = '''
if is_string(.image) && contains(string!(.image), ":") {
  .image_repository = split(string!(.image), r':')[0]
}
'''

# Note: uri option is not templateable
# https://github.com/vectordotdev/vector/issues/1155
[sinks.openobserve_docker_logs]
type = "http"
inputs = [ "docker_parser", ]
uri = "https://api.openobserve.ai/api/femiwiki_2lbGLNGsIgcwF9Y/docker_logs/_json"
method = "post"
auth.strategy = "basic"
auth.user = "admin@femiwiki.com"
auth.password = "OPENOBSERVE_PASSWORD"
compression = "gzip"
encoding.codec = "json"
encoding.timestamp_format = "rfc3339"
healthcheck.enabled = false
EOF
}

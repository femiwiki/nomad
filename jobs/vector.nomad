job "vector" {
  datacenters = ["dc1"]

  group "vector" {

    task "vector" {
      driver = "docker"

      template {
        data        = var.vector_toml
        destination = "/etc/vector/vector.toml"
      }

      config {
        image   = "timberio/vector:0.31.0-alpine"
        volumes = ["local/vector.toml:/etc/vector/vector.toml"]
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
inputs = ["vector_logs"]
uri = "https://api.openobserve.ai/api/femiwiki_2lbGLNGsIgcwF9Y/vector_logs/_json"
method = "post"
auth.strategy = "basic"
auth.user = "admin@femiwiki.com"
auth.password = "OPENOBSERVE PASSWORD"
compression = "gzip"
encoding.codec = "json"
encoding.timestamp_format = "rfc3339"
healthcheck.enabled = false

[sources.docker_logs]
type = "docker_logs"

[transforms.docker_json_parser]
inputs = ["docker_logs"]
type = "remap"
source = '''
if is_string(.image) && contains(string!(.image), ":") {
  .image_repository = split(string!(.image), r':')[0]
}

if is_json(string!(.message)) {
  .message.msg = parse_json!(string!(.message))
} else if is_string(.message) {
  .message = {"msg": .message}
}
'''

[sinks.openobserve_docker_logs]
type = "http"
inputs = ["docker_json_parser",]
uri = "https://api.openobserve.ai/api/femiwiki_2lbGLNGsIgcwF9Y/docker_logs/_json"
method = "post"
auth.strategy = "basic"
auth.user = "admin@femiwiki.com"
auth.password = "OPENOBSERVE PASSWORD"
compression = "gzip"
encoding.codec = "json"
encoding.timestamp_format = "rfc3339"
healthcheck.enabled = false
EOF
}

datacenter = "dc1"
data_dir = "/opt/consul"

server = true
bootstrap_expect = 1
# Cloud Auto-join
# - https://www.consul.io/docs/install/cloud-auto-join#amazon-ec2
retry_join = ["provider=aws tag_key=Name tag_value=femiwiki"]

ports {
  grpc = 8502
}

connect {
  enabled = true
}

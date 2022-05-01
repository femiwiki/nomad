# This file is for test. See https://github.com/femiwiki/femiwiki/issues/253 for details.

# TODO: Create csi plugin

# resource "nomad_job" "lb_consul_test" {
#   provider = nomad.consul_test
#   detach   = false
#   jobspec  = file("../jobs-consul-test/lb.nomad")

#   hcl2 {
#     enabled  = true
#     allow_fs = true
#   }
# }

# resource "nomad_job" "mysql_consul_test" {
#   provider = nomad.consul_test
#   depends_on = [
#     nomad_job.lb_consul_test,
#     nomad_volume.mysql,
#   ]
#   detach  = false
#   jobspec = file("../jobs-consul-test/mysql.nomad")

#   hcl2 {
#     enabled  = true
#     allow_fs = true
#   }
# }

# resource "nomad_job" "memcached_consul_test" {
#   provider = nomad.consul_test
#   depends_on = [
#     nomad_job.lb_consul_test,
#   ]
#   detach  = false
#   jobspec = file("../jobs-consul-test/memcached.nomad")

#   hcl2 {
#     enabled  = true
#     allow_fs = true
#   }
# }

# resource "nomad_job" "fastcgi_consul_test" {
#   provider = nomad.consul_test
#   depends_on = [
#     nomad_job.lb_consul_test,
#     nomad_job.mysql,
#     nomad_job.memcached,
#   ]

#   detach  = false
#   jobspec = file("../jobs-consul-test/fastcgi.nomad")

#   hcl2 {
#     enabled  = true
#     allow_fs = true
#   }
# }

# resource "nomad_job" "http_consul_test" {
#   provider = nomad.consul_test
#   depends_on = [
#     nomad_job.lb_consul_test,
#   ]
#   detach  = false
#   jobspec = file("../jobs-consul-test/http.nomad")

#   hcl2 {
#     enabled  = true
#     allow_fs = true
#   }
# }

# resource "nomad_job" "restbase_consul_test" {
#   provider = nomad.consul_test
#   depends_on = [
#     nomad_job.lb_consul_test,
#   ]
#   detach  = false
#   jobspec = file("../jobs-consul-test/restbase.nomad")

#   hcl2 {
#     enabled  = true
#     allow_fs = true
#   }
# }

페미위키 미디어위키 서버 [![Github checks Status]][Github checks Link]
========
한국의 페미니즘 위키인 [femiwiki.com]에 사용되는 미디어위키 서버입니다.
[Nomad]와 [Consul] 등에 필요한 다양한 코드를 담고있습니다.
데이터베이스와 memcached, 백업봇이 실행됩니다.

아래와 같이 간편하게 페미위키를 로컬에서 실행할 수 있습니다.

```bash
cp configs/secret.php.example configs/secret.php
cp nomad/development.example.hcl nomad/development.hcl
# Please make host volume paths available

sudo nomad agent -dev-connect -config nomad/development.hcl
consul agent -dev
nomad job run nomad/development.nomad
```

페미위키 개발하실 때엔 아래 커맨드들을 참고해주세요.

```bash
# configs/LocalSettings.php 검사
composer install
composer test
# configs/LocalSettings.php 자동 교정
composer fix
```

&nbsp;

### Production
페미위키는 프로덕션 배포에도 [Nomad]를 사용할 예정입니다.

프로덕션 배포를 할때엔 [secret.php] 에서 개발자모드를 반드시 꺼주세요.

다음 소프트웨어가 필요합니다.

- Docker
- Nomad
- Consul
- CNI network plugins

```sh
sudo ./up

# Run Docker daemon
sudo systemctl start docker

# Deploy the CSI plugin jobs
nomad job run nomad/plugin-ebs-controller.nomad
nomad job run nomad/plugin-ebs-nodes.nomad

# You must write volume.hcl file as described in the instruction
# - https://learn.hashicorp.com/tutorials/nomad/stateful-workloads-csi-volumes#deploy-the-ebs-plugin
# Register the volume
nomad volume register volume.hcl

nomad job run nomad/production.nomad
# TODO Use Terraform to run a job?
```

&nbsp;

--------

The source code of *femiwiki/mediawiki* is primarily distributed under the terms
of the [GNU Affero General Public License v3.0] or any later version. See
[COPYRIGHT] for details.

[Github checks Status]: https://badgen.net/github/checks/femiwiki/docker-mediawiki
[Github checks Link]: https://github.com/femiwiki/docker-mediawiki
[femiwiki.com]: https://femiwiki.com
[femiwiki/ami]: https://github.com/femiwiki/ami
[Nomad]: https://www.nomadproject.io/
[Consul]: https://www.consul.io/
[secret.php]: configs/secret.php.example
[GNU Affero General Public License v3.0]: LICENSE
[COPYRIGHT]: COPYRIGHT

# 페미위키 미디어위키 서버 [![Github checks Status]][github checks link]

한국의 페미니즘 위키인 [femiwiki.com]에 사용되는 미디어위키 서버입니다.
[Nomad], [Consul],[Terraform] 등에 필요한 다양한 코드를 담고있습니다.
데이터베이스와 memcached, 백업봇이 실행됩니다.

## Development

아래와 같이 간편하게 페미위키를 로컬에서 실행할 수 있습니다.

```bash
sudo nomad agent -dev-connect -config nomad/development.hcl
consul agent -dev
nomad job run jobs/development/mysql.nomad
nomad job run jobs/development/memcached.nomad
nomad job run jobs/development/fastcgi.nomad
nomad job run jobs/development/http.nomad
nomad job run jobs/development/parsoid.nomad
nomad job run jobs/development/restbase.nomad
```

이후 브라우저에서 [http://localhost:8080]를 방문할 수 있습니다.

## Production

페미위키는 프로덕션 배포에도 Nomad를 사용하고 있으며 이를 위해 [Nomad Provider]와 [Terraform Cloud]를 사용하고 있습니다. 그러면 서버에 Nomad를 준비하고 Terraform Cloud와 연결하는 작업이 필요합니다.

서버에는 다음 소프트웨어가 필요합니다.

- Docker
- Nomad
- Consul
- CNI network plugins

설치 후엔 이 리포지토리에 정의된 각 소프트웨어의 설정들을 적용해야 합니다.

```sh
git clone https://github.com/femiwiki/nomad.git
cd nomad
sudo ./up
```

이상의 과정은 실제로는 [femiwiki/infra]에 저장된 스크립트를 통해 인스턴스 Launch 후 자동으로 실행됩니다.

수작업으로는 Terraform Cloud와 Nomad cluster를 연결하기 위해 ACL을 시작하고 생성된 토큰을 Terraform Cloud에 저장하는 과정이 필요합니다. 다음을 실행해주세요.

```
$ ./nomad-acl-bootstrap
Nomad ACL Secret ID = 9184ec35-65d4-9258-61e3-0c066d0a45c5
```

nomad-acl-bootstrap은 `nomad acl bootstrap`을 실행하고 `NOMAD_TOKEN`으로 쓸 수 있는 Secret ID를 출력하면서 `.bashrc`에 환경 변수 설정을 추가합니다.
출력된 Secret ID를 [terraform cloud femiwiki/nomad workspace의 Variables 설정](https://app.terraform.io/app/femiwiki/workspaces/nomad/variables)에서 `nomad_token`으로 입력해주세요.

&nbsp;

---

The source code of _femiwiki/mediawiki_ is primarily distributed under the terms
of the [GNU Affero General Public License v3.0] or any later version. See
[COPYRIGHT] for details.

[github checks status]: https://badgen.net/github/checks/femiwiki/nomad
[github checks link]: https://github.com/femiwiki/nomad/actions
[femiwiki.com]: https://femiwiki.com
[nomad]: https://www.nomadproject.io/
[consul]: https://www.consul.io/
[nomad provider]: https://registry.terraform.io/providers/hashicorp/nomad
[terraform]: https://terraform.io/
[terraform cloud]: https://app.terraform.io/
[femiwiki/infra]: https://github.com/femiwiki/infra/blob/main/aws/res/bootstrap.sh
[secrets.php]: https://github.com/femiwiki/docker-mediawiki/blob/main/configs/secret.php.example
[gnu affero general public license v3.0]: LICENSE
[copyright]: COPYRIGHT

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

### Nomad 업그레이드

노드가 하나 뿐인 현재 세팅에서 Nomad를 업그레이드 해야 할 때는 다운타임을 가지고 수작업으로 모든 서비스를 내린 후 다시 생성하는 방법을 사용하여야 합니다.
단순히 바이너리만 교체할 경우 구 버전의 Nomad가 실행한 컨테이너가 추적되지 않아 새 Nomad가 띄우려고 하는 컨테이너와 포트 등이 충돌한 경험이 있습니다.

1. `nomad job stop -purge <NAME>`으로 fastcgi, mysql, http 등의 서비스를 내린다.
2. `nomad node status`로 node ID를 알아낸다.
3. 볼륨들을 모두 제거한다. (`nomad volume detach mysql <NODE_ID>; nomad volume detach caddycerts <NODE_ID>` → `nomad volume deregister`) 만일 aws-ebs0를 먼저 제거했다면 볼륨에 대한 작업을 할 수 없으므로 다시 살려야 한다.
4. 남은 모든 서비스를 내린다.
5. [스크립트](https://github.com/femiwiki/infra/blob/6e55a33bca89a1a89a96a6f1564353920dd2e885/aws/res/bootstrap.sh#L124-L126)를 참고해 바이너리를 교체한다.
6. `~/nomad` 디렉토리를 원하는 git 트리로 체크아웃한다.
7. aws-ebs-csi-driver를 `nomad job run jobs/plugin-ebs-controller.nomad; nomad job run jobs/plugin-ebs-nodes.nomad`로 올린다. depends_on이 꼬여서 미리 실행하지 않으면 https://github.com/femiwiki/nomad/issues/73 문제가 발생한다.
8. `nomad plugin status`로 플러그인 상태를 확인한다.
9. 테라폼 클라우드로 나머지를 모두 올린다.

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

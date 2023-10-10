# AWS S3 Backend migration 테스트

- AWS 에 Terraform S3 State 를 TFE, TFC 로 마이그레이션 하기 위한 테스트 코드 (v1.1 이하 버전)
- v1.1 이상 버전에서는 Remote 대신 Cloud (TFC 의 경우) 를 사용하기 때문에 Local 에 State 를 다운로드 받지 않아도 동작한다.
- v1.1 이상 버전에서도 아래 가이드한 형태의 마이그레이션도 가능할 것으로 보인다.
 
## SETUP

1. `main/01_s3_backend`  를 `terraform init` -> `terraform apply` 로 배포하여 S3 백엔드 리소스 생성

2.  `main/02_migration_to_tfe` 의 `provider.tf` 를 열어 provider 설정 하고 `version.tf` 파일을 열어 backend s3 를 1번에서 만든 리소스로 설정 
```bash
# provider.tf
provider "aws" {
  region  = "ap-northeast-2"
  version = "~> 2.0"
  #access_key = "<YOUR_ACCESS_KEY>"
  #secret_key = "<YOUR_SECRET_KEY>"
}

# version.tf
terraform {
  backend "s3" {
    bucket         = "s3backend-vt0gcxzxrkm9nj-state-bucket"
    key            = "daeung/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    role_arn       = "arn:aws:iam::960249453675:role/s3backend-vt0gcxzxrkm9nj-tf-assume-role"
    dynamodb_table = "s3backend-vt0gcxzxrkm9nj-state-lock"
  }
  ...
}

```

3. `main/02_migration_to_tfe` 를 `terraform init` -> `terraform apply` 로 배포

4.  S3 State 를 로컬로 다운로드
```bash
$ terraform state pull > terraform.tfstate
# windows only (\r\n 을 \n 으로 변경)
$ ((Get-Content .\terraform.tfstate) -join "`n") + "`n" | Set-Content -NoNewline .\terraform.tfstate
```

5.  Local State 파일을 Remote 로 마이그레이션
```bash
$ terraform init 

Initializing the backend...
Backend configuration changed!

Terraform has detected that the configuration specified for the backend
has changed. Terraform will now check for existing state in the backends.


Terraform detected that the backend type changed from "s3" to "remote".
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "s3" backend to the
  newly configured "remote" backend. No existing state was found in the newly
  configured "remote" backend. Do you want to copy this state to the new "remote"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "remote"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

6. terraform.tfstate 파일 삭제

7. terraform plan 으로 변경사항 없는지 확인
```bash
$ terraform plan
Running plan in the remote backend. Output will stream here. Pressing Ctrl-C
will stop streaming the logs, but will not stop the plan running remotely.

Preparing the remote plan...

To view this run in a browser, visit:
https://app.terraform.io/app/daeungkim/migration/runs/run-miwCBbpx3fv2NySm

Waiting for the plan to start...

Terraform v0.12.26
Initializing plugins and modules...
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.aws_ami.ubuntu: Refreshing state...
aws_instance.ec2: Refreshing state... [id=i-075d6eebf727a722a]

------------------------------------------------------------------------

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

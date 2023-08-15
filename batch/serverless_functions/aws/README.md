# Super Hero Combat Simulator - Dataflow - Kafka - Batch - AWS

## Amazon Web Services

Setup Instructions
 * Register with AWS [Here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html)
   * Create new user with limited priviledges and [IP restrictions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-ip.html)
   * Bind new user with IAMFullAccess Role
 * Install [AWS CLI](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-ip.html)
 * Configure [Shared Credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
 * Create a S3 bucket for Terraform tfstate files, so this is not stored locally and risks getting pushed to source repository. Update this bucket name in the backend.conf file
   * Creating a [S3 Bucket]()
   * Grant access to New User with Bucket IAM policy & configure Terraform tfstate backend to S3 - [Link](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

### Dev
```bash
terraform -chdir=batch/serverless_functions/aws init -backend-config=$(pwd)/batch/serverless_functions/aws/backend.conf && \
terraform -chdir=batch/serverless_functions/aws apply -auto-approve

docker-compose --env-file batch/kafka/env/local.env -f batch/kafka/compose/docker-compose.local.yml up -d redis build_db zookeeper kafka kafka-ui
```

```bash
export $(cat batch/kafka/env/aws.env)
python3 batch/kafka/worker_lib_server_lobby.py
# OR
python3 batch/kafka/worker_lib_server_game.py
```

```bash
export PLAYERS=10
docker-compose --env-file batch/kafka/env/local.env -f batch/kafka/compose/docker-compose.local.yml up --scale player=${PLAYERS} --scale worker_lib_server_game=0 --scale worker_lib_server_lobby=0
```


### Production
```bash
terraform -chdir=batch/serverless_functions/aws init -backend-config=backend.conf && \
terraform -chdir=batch/serverless_functions/aws apply -auto-approve

docker-compose --env-file batch/kafka/env/aws.env -f batch/kafka/compose/docker-compose.aws.yml up -d zookeeper kafka kafka-ui

export PLAYERS=10
docker-compose --env-file batch/kafka/env/aws.env -f batch/kafka/compose/docker-compose.aws.yml up --scale player=${PLAYERS}
```

Tear down

```bash
docker-compose --env-file batch/kafka/env/aws.env -f batch/kafka/compose/docker-compose.aws.yml down

terraform -chdir=batch/serverless_functions/aws apply -auto-approve -destroy
```


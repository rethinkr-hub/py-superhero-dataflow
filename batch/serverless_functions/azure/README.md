# Super Hero Combat Simulator - Dataflow - Kafka - Batch - Azure

## Azure

Setup Instructions
 * Register with Azure [Here](https://azure.microsoft.com/en-ca/free/)
   * Create new user with limited priviledges
   * Bind new user with IAMFullAccess Role
 * Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
 * Create a ADLS GenV2 Storage Account for Terraform tfstate files, so this is not stored locally and risks getting pushed to source repository. Update this bucket name in the backend.conf file
   * Creating a [ADLS GenV2 Storage Account](https://learn.microsoft.com/en-us/azure/storage/blobs/create-data-lake-storage-account)
   * Create a Terraform container inside the new Storage Account
   * Configure Terraform tfstate backend to Azurerm - [Link](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

### Dev
```bash
terraform -chdir batch/serverless_functions/azure -backend-config=backend.conf init && \
terraform -chdir batch/serverless-functions/azure -auto-approve apply

docker-compose --env-file batch/kafka/env/local.env -f batch/kafka/compose/docker-compose.local.yml up -d redis build_db zookeeper kafka kafka-ui
```

```bash
export $(cat batch/kafka/env/azure.env)
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
terraform -chdir batch/serverless_functions/azure -backend-config=backend.conf init && \
terraform -chdir batch/serverless_functions/azure -auto-approve apply

docker-compose --env-file batch/kafka/env/azure.env -f batch/kafka/compose/docker-compose.azure.yml up -d zookeeper kafka kafka-ui

export PLAYERS=10
docker-compose --env-file batch/kafka/env/azure.env -f batch/kafka/compose/docker-compose.azure.yml up --scale player=${PLAYERS}
```

Tear down

```bash
docker-compose --env-file batch/kafka/env/azure.env -f batch/kafka/compose/docker-compose.azure.yml down

terraform -chdir batch/serverless_functions/azure -auto-approve -destroy apply
```


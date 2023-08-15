# Super Hero Combat Simulator - Dataflow - Kafka - Batch - GCP

## Google Cloud Platform

Setup Instructions
 * Register with GCP [Here](https://console.cloud.google.com/freetrial)
   * Create a new Project
   * Register a new user account with limited privileges (Viewer Role)
   * Create a new Service Account with Security Admin Role and Service Account Admin Role
   * Bind IAM Service Account Token Generator Role to the new Secret Manager role with the Project Service Account
 * Enable APIs
   * Visit [https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=PROJECT_ID](https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview) and enable Cloud Resource Manager API (replace **PROJECT_ID** with your newly created Project ID)
   * Visit [https://console.developers.google.com/apis/api/cloudfunctions.googleapis.com/overview?project=PROJECT_ID](https://console.developers.google.com/apis/api/cloudfunctions.googleapis.com/overview) and enable Cloud Functions API (replace **PROJECT_ID** with your newly created Project ID)
   * Visit [https://console.developers.google.com/apis/api/cloudbuild.googleapis.com/overview?project=PROJECT_ID](https://console.developers.google.com/apis/api/cloudbuild.googleapis.com/overview) and enable Cloud Build API (replace **PROJECT_ID** with your newly created Project ID)
 * Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)
   * Configure [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
 * Create a GCS Bucket for Terraform tfstate files, so this is not stored locally and risks getting pushed to source repository. Update this bucket name in the backend.conf file
   * Creating a [GCS Bucket](https://cloud.google.com/storage/docs/creating-buckets)
   * Grant Access to New User Account the Storage Admin role to GCS Bucket
   * Configuring [Terraform tfstate Backend to GCS](https://cloud.google.com/docs/terraform/resource-management/store-state)

### Dev
```bash
terraform -chdir=batch/serverless_functions/gcp init -backend-config=$(pwd)/batch/serverless_functions/gcp/backend.conf && \
terraform -chdir=batch/serverless_functions/gcp apply -auto-approve

docker-compose --env-file batch/kafka/env/local.env -f batch/kafka/compose/docker-compose.local.yml up -d redis build_db zookeeper kafka kafka-ui
```

```bash
export $(cat batch/kafka/env/gcp.env)
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
terraform -chdir=batch/serverless_functions/gcp init -backend-config=backend.conf && \
terraform -chdir=batch/serverless_functions/gcp apply -auto-approve

docker-compose --env-file batch/kafka/env/gcp.env -f batch/kafka/compose/docker-compose.gcp.yml up -d zookeeper kafka kafka-ui

export PLAYERS=10
docker-compose --env-file batch/kafka/env/gcp.env -f batch/kafka/compose/docker-compose.gcp.yml up --scale player=${PLAYERS}
```

Tear down

```bash
docker-compose --env-file batch/kafka/env/gcp.env -f batch/kafka/compose/docker-compose.gcp.yml down

terraform -chdir=batch/serverless_functions/gcp apply -auto-approve -destroy
```


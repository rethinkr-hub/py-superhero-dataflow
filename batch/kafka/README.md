# Super Hero Combat Simulator - Dataflow - Kafka - Batch

Here is a demonstration of a Kafka Batch processing capabilities handling the [Super Hero Combat Simulator](https://github.com/jg-ghub/py-superhero) streaming data. Batch processing isn't a default behavior with the Kafka Broker. Instead, the Broker normally recieves a *Message Commital* from the consumer to indicate that the message was read and processed. On the *Message Commital*, the Broker increments the Topic's Offset, which statefully tells consumers that message below the offset have already been committed and no longer require processing.

Batch processing uses a completely different set of operations to process messages. The Broker no longer receives *Message Commitals* from the consumer, and doesn't track message offsets either. Instead, offsets are managed outside of Kafka so the consumers can manage this state on their own. In this demonstration, we use Redis to manage the state of message tracking, so the Worker service can mass consume messages, and then batch operate the ELT job over multiple messages instead of running the same ELT operation on each message individually.

# Overview

## Worker

The worker service listens to the Kafka Topics, whereby messages are streamed during the life-cycle of the game. For each message parsed by the worker, we extract meta information about the logged message like Buffer Meta and Log Meta. These meta tables contain valuable information in regard to bench marking performance in every stage of the log's life-cycle. The entire Batch process is also tracked in the ETL Meta tables.

The gameplay data is captured as the Task data, which the worker captures via these possible Topics

 * `lib.server.lobby` this topic streams all the data simulator messages from the server's lobby API. The particular messages of interest have a `log_message=='Starting Match'`. On these messages, the task array is filled with the message details for later ingestion into Blob Storage. These messages contain the participant information needed to model our dimension tables during analysis.

 * `lib.server.game` this topic streams all the data simulator messages from the server's game API. the particular messages of interest have a `log_message=='Attack Completed'`. On these messages, the task array is filled with the message details for later ingestion into Blob Storage. These messages contain the battle outcomes needed to model our fact tables during analysis.

The worker service is also responisble for managing the Batch process. This entails reading/writing the state of messages processed in Redis Keys, and completing the ETL job - transforming and loading log messages to Parquet files.

**State**
When the worker service is triggered, it will first load the previously completed state of operations from the following Redis keys

 * `kafka.partitions.{{ %logger_name% }}.state.counts`
 * `kafka.partitions.{{ %logger_name% }}.state.last_offset`

where `{{ %logger_name% }}` is either `lib.server.lobby` or `lib.server.game`. These two stateful properties are internally tracked throughout the messages consumed from the Kafka Broker. That is, each message increments the `state.counts` attribute by 1 and overwrites the `state.last_offset` attribute with the message's `offset` property. The worker seeks all messages past the `state.last_offset`, and processes them into their respective mappings. Once all messages are processed, then the worker overwrites the Redis keys with internally tracked state.

**ELT**
The worker service's Batch operation is responsible for transforming the buffered messages into Parquet files, and ingests them into Blob Storage defined by the Environment Variable `OUTPUT_FS`.

## Schema

### ETL Meta

| Field                 | Type            |
|-----------------------|-----------------|
| etl_id                | uft8            |
| service               | uft8            |
| mode                  | uft8            |
| timestamp_start       | timestamp('ms') |
| timestamp_end         | timestamp('ms') |

### Buffer Meta

| Field                 | Type            |
|-----------------------|-----------------|
| etl_id                | utf8            |
| msg_id                | utf8            |
| checksum              | utf8            |
| headers               | list[utf8]      |
| key                   | utf8            |
| offset                | uint64          |
| partition             | uint8           |
| serialized_key_size   | int16           |
| serialized_value_size | int16           |
| timestamp             | timestamp('ms') |
| timestamp_type        | uint8           |
| topic                 | utf8            |
| _is_protocol          | bool            |

### Log Meta

| Field                 | Type            |
|-----------------------|-----------------|
| etl_id                | utf8            |
| msg_id                | utf8            |
| level                 | utf8            |
| timestamp             | timestamp('ms') |
| name                  | utf8            |
| log_message           | utf8            |

### Lib_Server_Lobby

| Field                 | Type            |
|-----------------------|-----------------|
| etl_id                | utf8            |
| msg_id                | utf8            |
| game_token            | utf8            |
| user_token            | utf8            |
| superhero_id          | uint16          |
| superhero_attack      | uint64          |
| superhero_health      | uint64          |

### Lib_Server_Game

| Field                 | Type            |
|-----------------------|-----------------|
| etl_id                | utf8            |
| msg_id                | utf8            |
| timestamp             | timestamp('s')  |
| game_token            | utf8            |
| user_token            | utf8            |
| action                | utf8            |
| enemy_token           | utf8            |
| enemy_damage          | uint64          |
| enemy_health_prior    | uint64          |
| enemy_health_post     | uint64          |


## Environment Variables

| Variable Name         | Default   | Description                                                   |
|-----------------------|-----------|---------------------------------------------------------------|
| REDIS_HOST            | localhost | [str] Redis Host Address                                      |
| REDIS_PORT            | 6379      | [int] Redis Host Port                                         |
| REDIS_DB              | 0         | [int] Redis Databse                                           |
| REDIS_EXPIRY          | 30        | [int] Redis Key Expiry in seconds                             |
| WORKER_CHANNEL        | CLEAN     | [str] Redis/Kafka Pub/Sub Channel                             |
| CLEAN_ROUTINE         | False     | [bool] Flag to run Redis Clean                                |
| LOGGER_MODULE         | Default   | [str] Logging Module Name                                     |
| LOG_LEVEL             | INFO      | [str] Logging Message Level Filter                            |
| GCP_PROJECT_ID        |           | [str] Google Cloud Platform - Project ID                      |
| AWS_ACCESS_KEY_ID     |           | [str] Amazon Web Services - Access Key                        |
| AWS_SECRET_ACCESS_KEY |           | [str] Amazon Web Services - Secret Key                        |
| AZURE_ACCOUNT_NAME    |           | [str] Azure Blob Storage Name                                 |                     
| AZURE_ACCOUNT_KEY     |           | [str] Azure Blob Storage Key                                  |
| AZURE_TENANT_ID       |           | [str] Azure Tenant ID                                         |
| AZURE_CLIENT_ID       |           | [str] Azure Client ID                                         |
| AZURE_CLIENT_SECRET   |           | [str] Azure Client Secret                                     |

# Cloud

Here is the first step to getting data ingested into a production-ready Data Warehouse. In this demonstration, we're piping data from the Kafka Buffer to resilient/highly available Blob Storage for later modeling/analysis in the Data Warehouse. We're also utilizing an application called [Terraform](https://registry.terraform.io/) to deploy real Infrastructure as Code (IAC)/ Infrastructure as a Service (IAAS). Terraform wraps multiple Cloud Platform APis into its own agnostic API to deploy infrastruce on the cloud. In this demonstration, we're starting with Blob Storage on the following Providers

## Google Cloud Platform

Setup Instructions
 * Register with GCP [Here](https://console.cloud.google.com/freetrial)
 * Create Service Account [Here - Step 4](https://support.google.com/a/answer/7378726?hl=en)
 * Terraform adding Credentials [Here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials)

In our demonstration, we explicitly call out the GCP credentials file directly in the Terraform Provider for easier understanding instead of hiding everything in Environment Variables. Crawl before Run. 

```terraform
provider "google" {
  credentials = file("./gcloud_cred.json")
}
```

Save the JSON credential file in the `./cloud/gcp` folder and name it `gcloud_cred.json`. Create a file called `./cloud/gcp/terraform.tfvars`, and copy/paste the following (replacing with unique Bucket Name and [GCP Project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects))

```cfg
bucket_name = "[INPUT BUCKET NAME]"
storage_class = "REGIONAL"
project_id = "[INPUT GCP PROJECT ID]"
```

## Amazon Web Services

Setup Instructions
 * Register with AWS [Here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html)
 * Create Service Account [Here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html). Make sure to choose Programatic Access with the **AmazonS3FullAccess** role. Also, make sure to copy/export the Access Keys once complete - they won't be visible again.
 * Terraform adding Credentials [Here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

In our demonstration, we explicitly call out the AWS credentials directly in the Terraform Provider for easier understanding instead of hiding everything in Environment Variables. Crawl before Run. 

```terraform
provider "aws" {
    access_key = var.aws_access_key_id
    secret_key = var.aws_secret_access_key
}
```

Create a file called `./cloud/aws/terraform.tfvars`, and copy/paste the following (replacing with unique Bucket Name and [AWS Credential](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console))

```cfg
bucket_name = "[INPUT BUCKET NAME]"
aws_access_key_id = "[INPUT AWS ACCESS KEY ID]"
aws_secret_access_key = "[INPUT AWS ACCESS SECRET]"
```

## Azure

Setup Instructions
 * Register with Azure [Here](https://azure.microsoft.com/en-ca/free/)
 * Create Service Account and Register Application [Here](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal). Ignore Redirect URI when registering App, and ensure that **Owner** role is assigned
 * Terraform adding Credentials [Here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)

In our demonstration, we explicitly call out the Azure credentials directly in the Terraform Provider for easier understanding instead of hiding everything in Environment Variables. Crawl before Run. 

```terraform
provider "azurerm" {
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}
```

Create a file called `./cloud/azure/terraform.tfvars`, and copy/paste the following (replacing with unique Bucket Name and [Azure Credential](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#creating-a-service-principal))

```cfg
subscription_id="[INPUT AZURE SUBSCRIPTION ID]"
client_id="[INPUT AZURE CLIENT ID]"
client_secret="[INPUT AZURE CLIENT SECRET VALUE (NOT SECRET KEY)]"
tenant_id="[INPUT AZURE TENANT ID]"
```

## Deploy

Finally, we're ready to deploy our IAC and create dedictated Blob Storage for the Data Simulator on GCP.

**Initialize & Download Dependencies**
```bash
terraform init
```

***Dry Run**
```bash
terraform plan
```

**Deploy Infrastructure**
```bash
terraform apply
```

# Performance

Kafka is very capable of processing messages in Batch with a few tweaks to monitor state outside of Kafka itself. No other Pub/Sub or Message Queue is able to acheive both Batch and Streaming like Kafka can, which is why it's the winning solution in these evaluations. The Broker does require more configuration then the other solutions to truly enable the scalable potential (like partitioning a topic), but it's still trivial to adopt programmatically into the stack.

No winner was intended in the evaluation of Blob Storages, but instead we were surprised how easy it was to scale the ETL operation across multiple cloud providers with the brilliant design of PyArrow's multi FS compliancy. One important design requirement in DataOps is the ability to scale applications/operations across multiple Cloud Platform which is acheieved in this demonstration.

# How to Use

Make sure to spin up the Cloud Resources with Terraform in the Cloud steps above.

## Local Development

To test/debug these services, each service can be started locally by executing the script in bash. A Redis service must be running, and can easily be started separate from the other docker services. The following commands will have the server application running locally

```bash
export $(cat .env) && \
docker-compose -f compose/docker-compose.local.yml up -d redis build_db zookeeper kafka kafka-ui && \
python3 server.py
```

Once Kafka has had time to warm up, we can configure the Topics and start up the Workers

```bash
docker-compose -f compose/docker-compose.local.yml up -d kafka_config && \
python3 worker.py
```

After the configurations have been completed, we can deploy as many clients as we'd like with the following - repeat as necessary to meet required participants. Note: make sure that Kafka is not only up, but accepting publications as well. The HeartBeat for Kafka uptime isn't a proper signal that it's ready to receive Topic publications.

```bash
python3 client.py
```

To retry the Kafka Batch job, reset the following keys in Redis.

```bash
export REDIS_DB=0
redis-cli -h localhost -n ${REDIS_DB} -e SET kafka.partitions.lib.server.game.state.counts "{\"\": 0}"
redis-cli -h localhost -n ${REDIS_DB} -e SET kafka.partitions.lib.server.game.state.last_offset -1
```

## Production

Spinning up a production appliaction with docker-compose is faily simple, requiring 2 setps. The first step is to spin up the Kafka services and allow it time to be in a ready position to receive Topic publications.

```bash
docker-compose --env-file .env -f compose/docker-compose.local.yml build && \
docker-compose --env-file .env -f compose/docker-compose.local.yml up -d zookeeper kafka kafka-ui
```

Normally, once Kafka-UI is up and can be navigated to via webpage, then we can spin the rest of the application up following the commands below - replacing `${PLAYERS}` with the required participants.

```bash
export PLAYERS=10
docker-compose --env-file .env -f compose/docker-compose.local.yml up --scale player=${PLAYERS}
```

We can scale the workers with the following

```bash
export PLAYERS=10
export WORKERS=4
docker-compose --env-file .env -f compose/docker-compose.local.yml up --scale worker=${WORKERS} --scale player=${PLAYERS}
```

To migrate the buffered data in Kafka to GCP, run the following

```bash
docker-compose --env-file .env -f compose/docker-compose.gcp.yml up -d zookeeper kafka kafka-ui

export PLAYERS=10
docker-compose --env-file .env -f compose/docker-compose.gcp.yml up --scale player=${PLAYERS}
```

To migrate the buffered data in Kafka to AWS, run the following

```bash
docker-compose --env-file .env -f compose/docker-compose.aws.yml up -d zookeeper kafka kafka-ui

export PLAYERS=10
docker-compose --env-file .env -f compose/docker-compose.aws.yml up --scale player=${PLAYERS}
```

To migrate the buffered data in Kafka to Azure, run the following

```bash
docker-compose --env-file .env -f compose/docker-compose.azure.yml up -d zookeeper kafka kafka-ui

export PLAYERS=10
docker-compose --env-file .env -f compose/docker-compose.azure.yml up --scale player=${PLAYERS}
```

## TODO

* Scalability to Brokers
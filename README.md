# Super Hero Combat Simulator - Dataflow

This repo is an evaluation of Dataflow and Data Warehouse services for the [Super Hero Combat Simulator](https://github.com/jg-ghub/py-superhero). We'll come to undestand the possible persistence layers to house our raw simulator data in these demonstratione.

**Motivation:** provide replicatable demonstrations for some popular Datawarehouse Cloud services with a similar pattern style, so we can interchange services with simplicity.

**Objective:** Evaluate the benefits of building a Dataflow in Batch vs Stream operation, and which best suits the DataOps goals for this simulator. We use an identical ETL job to output streaming logs to Parquet files for ingestion into Data Warehouses. The ouput to Parquet files acheives a source/raw data starting point in the Data Warehouse to being tracking Data Lineage.

# Pattern

## Batch

The evaluation criteria for piping data to different Cloud DWs was made incredibly simple due to the efforts by the [Apache Arrow Project](https://github.com/apache/arrow) with the ability to change filesystems in PyArrow write functions. Arrow comes with some built-in filesystems OOTB, but can also implement ffspec-compatible filesystems. More on the subject [Here](https://arrow.apache.org/docs/python/filesystems.html)

In our parser, we're able to declare a filesystem at startup which `pyarrow.parquet` will use to output files. The filesystem is choosen based on the Environment Variable `OUTPUT_FS`

```python

# Environment Variables
OUTPUT_DIR=os.getenv('OUTPUT_DIR', '/usr/local/data/datasim_superhero')
OUTPUT_FS=os.getenv('OUTPUT_FS', 'LOCAL')

# Setup
if OUTPUT_FS == 'GCP':
    import gcsfs
    
    GCP_PROJECT_ID=os.getenv('GCP_PROJECT_ID', None)

    assert(not GCP_PROJECT_ID is None)
    filesystem = gcsfs.GCSFileSystem(
        project=GCP_PROJECT_ID, 
        token=os.path.join(os.path.base(__file__), 'gcp', 'gcloud_cred.json'))
        
elif OUTPUT_FS == 'AWS':
    import s3fs

    AWS_ACCESS_KEY_ID=os.getenv('AWS_ACCESS_KEY_ID', None)
    AWS_SECRET_ACCESS_KEY=os.getenv('AWS_SECRET_ACCESS_KEY', None)
    
    assert(not AWS_ACCESS_KEY_ID is None)
    assert(not AWS_SECRET_ACCESS_KEY is None)

    filesystem = s3fs.S3FileSystem(key=AWS_ACCESS_KEY_ID, secret=AWS_SECRET_ACCESS_KEY)

elif OUTPUT_FS == 'AZURE':
    import adlfs

    AZURE_ACCOUNT_NAME=os.getenv('AZURE_ACCOUNT_NAME', None)
    AZURE_ACCOUNT_KEY=os.getenv('AZURE_ACCOUNT_KEY', None)
    AZURE_TENANT_ID=os.getenv('AZURE_TENANT_ID', None)
    AZURE_CLIENT_ID=os.getenv('AZURE_CLIENT_ID', None)
    AZURE_CLIENT_SECRET=os.getenv('AZURE_CLIENT_SECRET', None)

    assert(not AZURE_ACCOUNT_NAME is None)
    assert(not AZURE_ACCOUNT_KEY is None)
    assert(not AZURE_TENANT_ID is None)
    assert(not AZURE_CLIENT_ID is None)
    assert(not AZURE_CLIENT_SECRET is None)
    filesystem = adlfs.AzureBlobFileSystem(
        account_name=AZURE_ACCOUNT_NAME,
        account_key=AZURE_ACCOUNT_KEY,
        tenant_id=AZURE_TENANT_ID,
        client_id=AZURE_CLIENT_ID,
        client_secret=AZURE_CLIENT_SECRET
    )
else:
    filesystem = fs.LocalFileSystem()

```

Now `pyarrow.parquet` can simply output to an BlobStorage we created in the Setup stage with the following

```python

pq.write_table(
    tbl,
    where=file_path,
    filesystem=filesystem,
    compression='gzip'
)

```

# Overview

## Batch

Batch Dataflow provides a cost effective pipeline for moving data from the buffer to the DW. The Batch operation relies on Kafka *seek* methods for moving across messages in it's buffer manually instead of the automated *Committed* offsets the consumers operate with by default. The ability to move through messages manually provides more stability that the message will be "read only once" instead of "read at least once" sustainability offered OOTB. This will reduce duplicates entering the DW, and cost less on ELT operations. Batch processing in Kafka was able to acheive a Stateful message tracker with the `Rebalance Listener` which hooked message counts by Topic/Partition into Redis Keys, so when the workers won't lose progress when Kafka natively rebalances itself.

Batch requires a scheduler to trigger the data migration from buffer to DW - which obviously had to be Airflow. We created 2 DAGs to trigger the data migration

**Scheduled**
This was an hourly trigger to move the latest messages into the DW in Parquet files. This sort of trigger is simple, and viable, in getting the buffered messgaes into the DW. However, the ETL parquet files may become disparate in size based on time of day. The Parquet files are paritioned by day, so this likely isn't an impact, but would cause some hours in the day to be a heavier read then others.

**Watcher**
This was a threshold watcher in the Kafka Topic to trigger the latest messages into the DW by number of outstanding messages. The watch polls the Kafka topic, and waits for the message size to reach a specific threshold before it triggers the worker to consume the buffered messages and migrate to DW. This DAG will likely keep a more uniform file size in the Parquet partitions.

## Cloud

This is the first installment in the Super Hero Data Simulator series to incorporate Cloud Resources. A futile attempt at finding a supported Docker orchestration for Hadoop/Hive lead to the reliance of Cloud Blob Storage, and inevitably Cloud Data Warehouse Services. Utilizing open source applications/ services helps to keep costs low (free in development); however, the choosen Cloud Platforms offer a free tier service which offers capacity/ bandwidth acceptable for the simulator's development use.


# Supporting Documents

Some POC documentation on File System implementation in PyArrow
[Filesystem Interface](https://arrow.apache.org/docs/python/filesystems.html)

Terraform GCP Provider
[Google Cloud Platform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

Terraform AWS Provider
[Amazon Web Services Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

AWS Policy Generator
[AWS Policy Generator](https://awspolicygen.s3.amazonaws.com/policygen.html)

Terraform Azure Provider
[Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
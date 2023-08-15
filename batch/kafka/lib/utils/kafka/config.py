# https://docs.confluent.io/platform/current/clients/confluent-kafka-python/html/index.html#confluent_kafka.admin.AdminClient

from confluent_kafka.admin import AdminClient, NewTopic, NewPartitions

import logging
import sys
import os

# Environment Variables
KAFKA_HOST=os.getenv('KAFKA_HOST', 'localhost')
KAFKA_PORT=int(os.getenv('KAFKA_PORT', 9092))

# Setup
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
KAFKA_URL = '%s:%d' % (KAFKA_HOST, KAFKA_PORT)

client = AdminClient({'bootstrap.servers': KAFKA_URL})
topic_config = {
    'client.__main__': {
        'partitions': 1,
        'replication': 1
    },
    'lib.server.game': {
        'partitions': 4,
        'replication': 1
    },
    'lib.server.lobby': {
        'partitions': 2,
        'replication': 1
    }
}

def _create_topics(topics):
    if len(topics) > 0:
        fs = client.create_topics(topics)
        for t, f in fs.items():
            try:
                logging.info('Creating Topic {}'.format(t))
                f.result()
            except Exception as e:
                logging.error('Failed to Create Topic {}: {}'.format(t.topic, e))

def _create_partitions(partitions):
    if len(partitions) > 0:
        fs = client.create_partitions(partitions)
        for t, f in fs.items():
            try:
                logging.info('Creating Partition {}'.format(t))
                f.result()
            except Exception as e:
                logging.error('Failed to create topic {}: {}'.format(t, e))

def main():
    topics = []
    partitions = []
    existing_topics = client.list_topics()
    brokers = list(existing_topics.brokers.keys())

    for t, vals in topic_config.items():
        if t in existing_topics.topics:
            if len(existing_topics.topics[t].partitions.keys()) < vals['partitions']:
                partitions.append(NewPartitions(t, vals['partitions']))
        else:
            topics.append(NewTopic(t, vals['partitions'], replication_factor=vals['replication']))

    _create_topics(topics)
    _create_partitions(partitions)


if __name__ == '__main__':
    logging.info('Starting to Configure Kafka Topics')
    main()
    logging.info('Kafka Topic Configuration Complete')
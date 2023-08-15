# https://aiokafka.readthedocs.io/en/stable/examples/local_state_consumer.html

from aiokafka.errors import OffsetOutOfRangeError
from aiokafka import ConsumerRebalanceListener
from lib.pubsub.redis import R_CONN
from collections import Counter

import asyncio
import logging
import json
import sys

# Setup
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

class RebalanceListener(ConsumerRebalanceListener):

    def __init__(self, consumer, topic_state):
        self.consumer = consumer
        self.topic_state = topic_state

    async def on_partitions_revoked(self, revoked):
        logging.info('Revoked {}'.format(revoked))
        self.topic_state.dump_state(revoked=True)

    async def on_partitions_assigned(self, assigned):
        logging.info('Assigned {}'.format(assigned))
        self.topic_state.load_state(assigned)
        for tp in assigned:
            last_offset = self.topic_state.get_last_offset(tp)
            if last_offset < 0:
                await self.consumer.seek_to_beginning(tp)
            else:
                self.consumer.seek(tp, last_offset + 1)


class RedisState:

    def __init__(self):
        self._counts = {}
        self._offsets = {}
        self._run_counts = {}

    def dump_state(self, revoked=False):
        for tp in self._counts:
            if not revoked:
                self._counts[tp] += self._run_counts[tp]
            
            R_CONN.set('kafka.topic.%s.partition.%d.state.last_offset' % (tp.topic, tp.partition), self._offsets[tp])
            R_CONN.set('kafka.topic.%s.partition.%d.state.counts' % (tp.topic, tp.partition), json.dumps(dict(self._counts[tp])))

    def load_state(self, partitions):
        self._counts.clear()
        self._offsets.clear()
        for tp in partitions:
            offset = R_CONN.get('kafka.topic.%s.partition.%d.state.last_offset' % (tp.topic, tp.partition))
            counts = R_CONN.get('kafka.topic.%s.partition.%d.state.counts' % (tp.topic, tp.partition))

            self._offsets[tp] = int(offset.decode('utf8')) if offset else -1
            self._counts[tp] = Counter(json.loads(counts.decode('utf8'))) if counts else Counter({tp.partition: 0})
            if tp not in self._run_counts or not self._run_counts[tp]:
                self._run_counts[tp] = Counter({tp.partition: 0})

    def add_counts(self, tp, counts, last_offset):
        self._run_counts[tp][tp.partition] += counts
        self._offsets[tp] = last_offset

    def get_last_offset(self, tp):
        return self._offsets[tp]

    def discard_state(self, tps):
        for tp in tps:
            self._offsets[tp] = -1
            self._counts[tp] = Counter({tp.partition: 0})


async def save_state_every_second(topic_state):
    while True:
        try:
            await asyncio.sleep(1)
        except asyncio.CancelledError:
            break
        topic_state.dump_state()
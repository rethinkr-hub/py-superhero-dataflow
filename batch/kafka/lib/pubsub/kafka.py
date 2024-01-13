#https://github.com/aio-libs/aiokafka/blob/master/examples/local_state_consumer.py

from lib.utils.kafka import rebalance
from collections import Counter
from functools import wraps

import aiokafka
import asyncio
import logging
import kafka
import sys
import os

# Environment Variables
KAFKA_HOST=os.getenv('KAFKA_HOST', 'localhost')
KAFKA_PORT=int(os.getenv('KAFKA_PORT', 9093))
WORKER_CHANNEL=os.getenv('WORKER_CHANNEL', 'lib.server.game')
BATCH_CONTINUOUS=eval(os.getenv('BATCH_CONTINUOUS', 'True'))
BATCH_SIZE=int(os.getenv('BATCH_SIZE', 1000))

# Setup
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
KAFKA_URL = '%s:%d' % (KAFKA_HOST, KAFKA_PORT)

class Kafka_Subscriber(object):

    @property
    def etl_func(self):
        return
    
    @etl_func.setter
    def etl_func(self, func):
        self._etl_func = func
    
    @property
    def start_func(self):
        return
    
    @start_func.setter
    def start_func(self, func):
        self._start_func = func
    
    @property
    def end_func(self):
        return
    
    @end_func.setter
    def end_func(self, func):
        self._end_func = func

    async def connect(self):
        try:
            # Get cluster layout and join group `superhero_sim`
            logging.info('Connecting to Kafka')
            self.connection = aiokafka.AIOKafkaConsumer(
                bootstrap_servers=KAFKA_URL,
                group_id="superhero_sim",           # Consumer must be in a group to commit
                enable_auto_commit=False,           # Will disable autocommit
                auto_offset_reset="none",
                key_deserializer=lambda key: key.decode("utf-8") if key else "",
            )
            
        except kafka.errors.KafkaConnectionError:
            await asyncio.sleep(1)
            await self.connect()
        except kafka.errors.CoordinatorNotAvailableError:
            await asyncio.sleep(1)
            pass

    async def run(self, runs=0):
        # Configure State Management
        await self.connection.start()

        topic_state = rebalance.RedisState()
        listener = rebalance.RebalanceListener(self.connection, topic_state)
        self.connection.subscribe(topics=[WORKER_CHANNEL], listener=listener)

        save_task = asyncio.create_task(rebalance.save_state_every_second(topic_state))

        try:
            self._start_func()
            while BATCH_CONTINUOUS or runs==0:
                try:
                    msg_set = await self.connection.getmany(timeout_ms=1000)
                except aiokafka.errors.OffsetOutOfRangeError as err:
                    # This means that saved file is outdated and should be
                    # discarded
                    tps = err.args[0].keys()
                    topic_state.discard_state(tps)
                    await self.connection.seek_to_beginning(*tps)
                    continue
                except aiokafka.errors.NoOffsetForPartitionError as err:
                    tps = err.args[0]
                    topic_state.discard_state([tps])
                    await self.connection.seek_to_beginning(tps)
                    continue

                for tp, msgs in msg_set.items():
                    for msg in msgs:
                        self._etl_func(msg)
                        topic_state.add_counts(tp, 1, msg.offset)

                    await asyncio.sleep(1)
                    if not BATCH_CONTINUOUS or topic_state._run_counts[tp][tp.partition] > BATCH_SIZE:
                        self._end_func()
                        topic_state._run_counts[tp] = Counter({tp.partition: 0})
                        self._start_func()
                
                runs+=1

        finally:
            await self.connection.stop()
            save_task.cancel()
            await save_task
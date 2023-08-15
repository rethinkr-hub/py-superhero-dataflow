import logging
import redis
import json
import sys
import os

# Envionrment Variabels
WORKER_CHANNEL=os.getenv('WORKER_CHANNEL', 'lib.server.lobby')
REDIS_HOST=os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT=int(os.getenv('REDIS_PORT', '6379'))
REDIS_DB=os.getenv('REDIS_DB', 0)

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

# Setup
R_POOL = redis.ConnectionPool(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB)
R_CONN = redis.Redis(connection_pool=R_POOL, decode_responses=True)

class Redis_Subscriber:

    @property
    def callback_function(self):
        return
    
    @callback_function.setter
    def callback_function(self, callback_function):
        self._callback_function = callback_function
    
    async def run(self):
        sub = R_CONN.pubsub()
        sub.subscribe(WORKER_CHANNEL)
        for msg in sub.listen():
            if isinstance(msg['data'], bytes):
                msg = json.loads(msg['data'].decode('utf8'))
                await self._callback_function()
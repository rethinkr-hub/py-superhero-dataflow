from lib.worker import sub_lib_server_game
from lib.pubsub.redis import Redis_Subscriber

import asyncio
import os

# Environment Variable
BATCH_CONTINUOUS=eval(os.getenv('BATCH_CONTINUOUS', 'True'))

async def main():
    if not BATCH_CONTINUOUS:
        subscriber = Redis_Subscriber()
        subscriber.callback_function = sub_lib_server_game
        await subscriber.run()
    else:
        await sub_lib_server_game()

if __name__ == '__main__':
    asyncio.run(main())
    
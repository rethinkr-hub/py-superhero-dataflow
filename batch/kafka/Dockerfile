FROM python/datasim/superhero

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
RUN apt-get update && apt-get install curl -y && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

COPY ./lib/utils/loggers/kafka.py ./lib/utils/loggers
COPY ./lib/utils/kafka ./lib/utils/kafka
COPY ./lib/pubsub/kafka.py ./lib/pubsub
COPY ./lib/pubsub/redis.py ./lib/pubsub
COPY ./lib/worker ./lib/worker
COPY ./worker_lib_server_game.py .
COPY ./worker_lib_server_lobby.py .

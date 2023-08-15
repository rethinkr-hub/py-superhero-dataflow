#!/usr/bin/env python

# Fork of websockets Quick Start
# https://websockets.readthedocs.io/en/stable/intro/quickstart.html

# Websocket History & Areas of Improvement
# https://ably.com/topic/websockets

from lib.worker.parser import ETL_Lib_Server_Game, ETL_Lib_Server_Lobby
from lib.pubsub.kafka import Kafka_Subscriber
from lib.pubsub.redis import R_CONN

import importlib
import datetime
import logging
import os

# Enviornment Variables
REDIS_EXPIRY=int(os.getenv('REDIS_EXPIRY', 30))
WORKER_CHANNEL=os.getenv('WORKER_CHANNEL', 'ARCHIVE')
CLEAN_ROUTINE=eval(os.getenv('WORKER_ROUTINE', 'False'))
LOGGER_MODULE=os.getenv('LOGGER_MODULE', 'default')

# Setup
logger_module = importlib.import_module('lib.utils.loggers', LOGGER_MODULE)

QUEUE='worker.%s' % __name__
logger=logging.getLogger('%s.%s' % (LOGGER_MODULE, QUEUE))

client_lib_server_lobby = ETL_Lib_Server_Lobby()
client_lib_server_game = ETL_Lib_Server_Game()

def lib_server_lobby_start():
    logging.info('Starting lib.server.lobby ETL')
    client_lib_server_lobby.start_time = datetime.datetime.now()

def lib_server_lobby_end():
    logging.info('Completed lib.server.lobby ETL')
    client_lib_server_lobby.end_time = datetime.datetime.now()
    if len(client_lib_server_lobby.tasks) > 0:
        _lib_server_lobby_load()
        client_lib_server_lobby.clean()

def lib_server_lobby_extract_transform(msg):
    logger.info('Running lib.server.lobby Routine')

    msg, log, task = client_lib_server_lobby.extract(msg)
    client_lib_server_lobby.generate_msg_id()
    client_lib_server_lobby.transform_buffer(msg)
    client_lib_server_lobby.transform_log(log)
    client_lib_server_lobby.transform(log, task)

def _lib_server_lobby_load():
    client_lib_server_lobby.transform_etl()
    client_lib_server_lobby.load_json(client_lib_server_lobby.etl, 'etl_meta')
    client_lib_server_lobby.load_json(client_lib_server_lobby.buffers, 'buffer_meta')
    client_lib_server_lobby.load_json(client_lib_server_lobby.logs, 'log_meta')
    client_lib_server_lobby.load_json(client_lib_server_lobby.tasks, 'lib_server_lobby')

def lib_server_game_start():
    logging.info('Starting lib.server.game ETL')
    client_lib_server_game.start_time = datetime.datetime.now()

def lib_server_game_end():
    logging.info('Completed lib.server.game ETL')
    client_lib_server_game.end_time = datetime.datetime.now()
    if len(client_lib_server_game.tasks) > 0:
        _lib_server_game_load()
        client_lib_server_game.clean()

def lib_server_game_extract_transform(msg):
    logger.info('Running lib.server.game Routine')

    msg, log, task = client_lib_server_game.extract(msg)
    client_lib_server_game.generate_msg_id()
    client_lib_server_game.transform_buffer(msg)
    client_lib_server_game.transform_log(log)
    client_lib_server_game.transform(log, task)

def _lib_server_game_load():
    client_lib_server_game.transform_etl()
    client_lib_server_game.load_json(client_lib_server_game.etl, 'etl_meta')
    client_lib_server_game.load_json(client_lib_server_game.buffers, 'buffer_meta')
    client_lib_server_game.load_json(client_lib_server_game.logs, 'log_meta')
    client_lib_server_game.load_json(client_lib_server_game.tasks, 'lib_server_game')
    
def clean(msg, host):
    if msg['log_message'] == 'Cleaning Game Records':
        host = R_CONN.get('games:%s:host' % msg['task']['GAME_TOKEN'])
        if CLEAN_ROUTINE:
            logger.info('Cleaning Records', (msg['task']['GAME_TOKEN'], msg['task']['USER_TOKEN']))
            R_CONN.expire('games:%s:superheros:%s' % (msg['task']['GAME_TOKEN'], msg['task']['USER_TOKEN']), REDIS_EXPIRY)
                
            if host:
                participants = int(R_CONN.get('games:%s:participants' % msg['task']['GAME_TOKEN']))
                R_CONN.expire('games:%s:order' % msg['task']['GAME_TOKEN'], REDIS_EXPIRY)
                R_CONN.expire('games:%s:status' % msg['task']['GAME_TOKEN'], REDIS_EXPIRY)
                R_CONN.expire('games:%s:participants' % msg['task']['GAME_TOKEN'], REDIS_EXPIRY)
                R_CONN.expire('games:%s:host' % msg['task']['GAME_TOKEN'], REDIS_EXPIRY)
                
                R_CONN.zrem('games:participants', msg['task']['GAME_TOKEN'])
                R_CONN.lrem('games:participants:%d' % participants, 1, msg['task']['GAME_TOKEN'])
                R_CONN.lrem('games:%s:logs' % msg['task']['GAME_TOKEN'])

async def sub_lib_server_game():
    subscriber = Kafka_Subscriber()
    subscriber.start_func = lib_server_game_start
    subscriber.end_func = lib_server_game_end
    subscriber.etl_func = lib_server_game_extract_transform
    await subscriber.connect()
    await subscriber.run()

async def sub_lib_server_lobby():
    subscriber = Kafka_Subscriber()
    subscriber.start_func = lib_server_lobby_start
    subscriber.end_func = lib_server_lobby_end
    subscriber.etl_func = lib_server_lobby_extract_transform
    await subscriber.connect()
    await subscriber.run()
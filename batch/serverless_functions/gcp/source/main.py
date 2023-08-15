# https://developer.ibm.com/articles/bd-archpatterns3/
# https://lingarogroup.com/blog/data-lake-architecture

from functools import wraps

import pyarrow.parquet as pq
import functions_framework
import pyarrow as pa
import datetime
import logging
import gcsfs
import json
import sys
import os
import re

# Environment Variables
OUTPUT_BUCKET=os.getenv('OUTPUT_BUCKET', 'gs://datasim-superhero-dataflow-standard')
GCP_PROJECT_ID=os.getenv('GCP_PROJECT_ID', None)
GCP_TOKEN=os.getenv('GCP_TOKEN', 'cloud')

# Setup
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

SCHEMA_ETL_META = pa.schema({
    'etl_id': pa.utf8(),
    'service': pa.utf8(),
    'mode': pa.utf8(),
    'timestamp_start': pa.timestamp('ms'),
    'timestamp_end': pa.timestamp('ms')
})

SCHEMA_BUFFER_META = pa.schema({
    'etl_id': pa.utf8(),
    'msg_id': pa.utf8(),
    'checksum': pa.utf8(),
    'headers': pa.list_(pa.utf8()),
    'key': pa.utf8(),
    'offset': pa.uint64(),
    'partition': pa.uint8(),
    'serialized_key_size': pa.int16(),
    'serialized_value_size': pa.int16(),
    'timestamp': pa.timestamp('ms'),
    'timestamp_type': pa.uint8(),
    'topic': pa.utf8(),
    '_is_protocol': pa.bool_(),
})

SCHEMA_LOG_META = pa.schema({
    'etl_id': pa.utf8(),
    'msg_id': pa.utf8(),
    'level': pa.utf8(),
    'timestamp': pa.timestamp('ms'),
    'name': pa.utf8(),
    'log_message': pa.utf8()
})

SCHEMA_LIB_SERVER_LOBBY = pa.schema({
    'etl_id': pa.utf8(),
    'msg_id': pa.utf8(),
    'game_token': pa.utf8(),
    'user_token': pa.utf8(),
    'superhero_id': pa.uint16(),
    'superhero_attack': pa.uint64(),
    'superhero_health': pa.uint64(),
})

SCHEMA_LIB_SERVER_GAME = pa.schema({
    'etl_id': pa.utf8(),
    'msg_id': pa.utf8(),
    'timestamp': pa.timestamp('s'),
    'game_token': pa.utf8(),
    'user_token': pa.utf8(),
    'action': pa.utf8(),
    'enemy_token': pa.utf8(),
    'enemy_damage': pa.uint64(),
    'enemy_health_prior': pa.uint64(),
    'enemy_health_post': pa.uint64(),
})

def load_json(bucket, name):
    filesystem = gcsfs.GCSFileSystem(project=GCP_PROJECT_ID, token=GCP_TOKEN)
    file_path = os.path.join(bucket, name)
    logging.info('Loading JSON %s' % file_path)

    with filesystem.open(os.path.join(bucket, name), 'rb', compression='gzip') as f:
        return json.load(f)

def write_parquet(data, file_name, schema):
    filesystem = gcsfs.GCSFileSystem(project=GCP_PROJECT_ID, token=GCP_TOKEN)
    file_path = os.path.join(
        OUTPUT_BUCKET, 
        re.sub('.json', '.parquet', re.sub('raw', 'standard', file_name)))
    
    logging.info('Writing Parquet %s' % file_path)
    map = {}
    for k in schema.names:
        map[k] = []
    
    for r in data:
        for k in r.keys():
            map[k].append(r[k])
    
    tbl = pa.Table.from_pydict(
        dict(zip(schema.names, tuple([map[c] for c in map.keys()]))),
        schema=schema
    )

    pq.write_table(
        tbl,
        where=file_path,
        filesystem=filesystem,
        compression='gzip'
    )

def transform_etl(raw):
    logging.info('Transforming ETL messages')

    data = []
    for r in raw:
        data.append({
            'etl_id': r['etl_id'],
            'service': r['service'],
            'mode': r['mode'],
            'timestamp_start': datetime.datetime.strptime(r['timestamp_start'], '%Y-%m-%dT%H:%M:%S.%f'),
            'timestamp_end': datetime.datetime.strptime(r['timestamp_end'], '%Y-%m-%dT%H:%M:%S.%f')
        })
    
    return data

def validate_buffer(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        logging.info('Validating Buffer messages')

        raw = args[0]
        for r in raw:
            assert(isinstance(r['checksum'] if r['checksum'] else 'NA', str))
            assert(isinstance(r['headers'] if r['headers'] else [], list))
            for h in r['headers']:
                assert(isinstance(h if h else 'NA', str))
        
            assert(isinstance(r['key'] if r['key'] else 'NA', str))
            assert(isinstance(r['offset'] if r['offset'] else 0, int))
            assert(isinstance(r['partition'] if r['partition'] else 0, int))
            assert(isinstance(r['serialized_key_size'] if r['serialized_key_size'] else 0, int))
            assert(isinstance(r['serialized_value_size'] if r['serialized_value_size'] else 0, int))
            assert(isinstance(datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'), datetime.datetime))
            assert(isinstance(r['timestamp_type'] if r['timestamp_type'] else 0, int))
            assert(isinstance(r['topic'] if r['topic'] else 'NA', str))
            assert(isinstance(r['_is_protocol'] if r['_is_protocol'] else False, bool))

        return f(*args, **kwargs)
    
    return wrapper

@validate_buffer
def transform_buffer(raw):
    logging.info('Transforming Buffer messages')

    data = []
    for r in raw:
        data.append({
            'etl_id': r['etl_id'],
            'msg_id': r['msg_id'],
            'checksum':r['checksum'],
            'headers': r['headers'],
            'key': r['key'],
            'offset': r['offset'],
            'partition': r['partition'],
            'serialized_key_size': r['serialized_key_size'],
            'serialized_value_size': r['serialized_value_size'],
            'timestamp': datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'),
            'timestamp_type': r['timestamp_type'],
            'topic': r['topic'],
            '_is_protocol': r['_is_protocol'],
        })
    
    return data

def validate_log(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        logging.info('Validating Log messages')

        raw = args[0]
        for r in  raw:
            assert('level' in r and isinstance(r['level'] if r['level'] else 'NA', str))
            assert('timestamp' in r and isinstance(r['timestamp'] if r['timestamp'] else 'NA', str))
            assert(isinstance(datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'), datetime.datetime))
            assert('name' in r and isinstance(r['name'] if r['name'] else 'NA', str))
            assert('log_message' in r and isinstance(r['log_message'] if r['log_message'] else 'NA', str))

        return f(*args, **kwargs)
    
    return wrapper

@validate_log
def transform_log(raw):
    logging.info('Transforming Log messages')

    data = []
    for r in raw:
        data.append({
            'etl_id': r['etl_id'],
            'msg_id': r['msg_id'],
            'level': r['level'],
            'timestamp': datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'),
            'name': r['name'],
            'log_message': r['log_message'],
        })
    
    return data

def validate_lib_server_lobby(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        logging.info('Validating lib.server.lobby messages')

        raw = args[0]
        for r in raw:
            assert('timestamp' in r and isinstance(datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'), datetime.datetime))
            assert('game_token' in r and isinstance(r['game_token'], str))
            assert('user_token' in r and  isinstance(r['user_token'], str))
            assert('superhero_id' in r and isinstance(r['superhero_id'], str))
            assert('superhero_attack' in r and isinstance(r['superhero_attack'], int))
            assert('superhero_health' in r and isinstance(r['superhero_health'], int))
        
        return f(*args, **kwargs)
    
    return wrapper

@validate_lib_server_lobby
def transform_lib_server_lobby(raw):
    logging.info('Transforming lib.server.lobby messages')

    data = []
    for r in raw:
        data.append({
            'etl_id': r['etl_id'],
            'msg_id': r['msg_id'],
            'timestamp': datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'),
            'game_token': r['game_token'],
            'user_token': r['user_token'],
            'superhero_id': r['superhero_id'],
            'superhero_attack': r['superhero_attack'],
            'superhero_health': r['superhero_health'],
        })
    
    return data

def validate_lib_server_game(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        logging.info('Validating lib.server.game messages')

        raw = args[0]
        for r in raw:
            assert('timestamp' in r and isinstance(datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'), datetime.datetime))
            assert('game_token' in r and isinstance(r['game_token'], str))
            assert('user_token' in r and  isinstance(r['user_token'], str))
            assert('action' in r and isinstance(r['action'], str))
            assert('enemy_token' in r and isinstance(r['enemy_token'], str))
            assert('enemy_damage' in r and isinstance(r['enemy_damage'], int))
            assert('enemy_health_prior' in r and isinstance(r['enemy_health_prior'], int))
            assert('enemy_health_post' in r and isinstance(r['enemy_health_post'], int))
        
        return f(*args, **kwargs)
    
    return wrapper

@validate_lib_server_game
def transform_lib_server_game(raw):
    logging.info('Transforming lib.server.game messages')

    data = []
    for r in raw:
        data.append({
            'etl_id': r['etl_id'],
            'msg_id': r['msg_id'],
            'timestamp': datetime.datetime.strptime(r['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'),
            'game_token': r['game_token'],
            'user_token': r['user_token'],
            'action': r['action'],
            'enemy_token': r['enemy_token'],
            'enemy_damage': r['enemy_damage'],
            'enemy_health_prior': r['enemy_health_prior'],
            'enemy_health_post': r['enemy_health_post'],
        })
    
    return data

# Triggered by a change in a storage bucket
@functions_framework.cloud_event
def run(cloud_event):
    logging.info('Bucket:%s Blob:%s | Initiating ELT trigger' % (
        cloud_event.data['bucket'], cloud_event.data['name']
    ))

    raw = load_json(cloud_event.data['bucket'], cloud_event.data['name'])

    if 'etl_meta/' in cloud_event.data['name']:
        data = transform_etl(raw)
        write_parquet(data, cloud_event.data['name'], SCHEMA_ETL_META)
    elif 'buffer_meta/' in cloud_event.data['name']:
        data = transform_buffer(raw)
        write_parquet(data, cloud_event.data['name'], SCHEMA_BUFFER_META)
    elif 'log_meta/' in cloud_event.data['name']:
        data = transform_log(raw)
        write_parquet(data, cloud_event.data['name'], SCHEMA_LOG_META)
    elif 'lib_server_lobby/' in cloud_event.data['name']:
        data = transform_lib_server_lobby(raw)
        write_parquet(data, cloud_event.data['name'], SCHEMA_LIB_SERVER_LOBBY)
    elif 'lib_server_game/' in cloud_event.data['name']:
        data = transform_lib_server_game(raw)
        write_parquet(data, cloud_event.data['name'], SCHEMA_LIB_SERVER_GAME)

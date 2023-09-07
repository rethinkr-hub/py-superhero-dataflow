from fsspec.implementations.local import LocalFileSystem
from functools import wraps

import pyarrow.parquet as pq
import pyarrow as pa
import datetime
import json
import uuid
import os

# Environment Variables
AWS_PROFILE=os.getenv('AWS_PROFILE', 'datasim-profile')
OUTPUT_DIR=os.getenv('OUTPUT_DIR', '/usr/local/data/datasim_superhero')
OUTPUT_FS=os.getenv('OUTPUT_FS', 'LOCAL')

# Setup
if OUTPUT_FS == 'GCP':
    # Credentials DOC
    #
    # https://cloud.google.com/docs/authentication/application-default-credentials

    import gcsfs
    
    GCP_PROJECT_ID=os.getenv('GOOGLE_CLOUD_PROJECT', None)
    GCP_TOKEN=os.getenv('GCP_TOKEN', 'google_default')

    assert(not GCP_PROJECT_ID is None)
    filesystem = gcsfs.GCSFileSystem(
        project=GCP_PROJECT_ID, 
        token=GCP_TOKEN)
        
elif OUTPUT_FS == 'AWS':
    # Credentials DOC
    #
    # https://s3fs.readthedocs.io/en/latest/#credentials
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

    import s3fs

    filesystem = s3fs.S3FileSystem(profile=AWS_PROFILE)

elif OUTPUT_FS == 'AZURE':
    # Credentials DOC
    #
    # https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash
    # https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity.defaultazurecredential?view=azure-python
    
    import adlfs

    AZURE_ACCOUNT_NAME=os.getenv('AZURE_ACCOUNT_NAME', None)

    assert(not AZURE_ACCOUNT_NAME is None)
    filesystem = adlfs.AzureBlobFileSystem(
        account_name=AZURE_ACCOUNT_NAME,
        anon=False,
        exclude_environment_credential=True,
        exclude_managed_identity_credential=True,
        exclude_powershell_credential=True,
        exclude_visual_studio_code_credential=True,
        exclude_shared_token_cache_credential=True
    )
else:
    filesystem = LocalFileSystem()

def validate_buffer(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        parser, buffer = args

        assert(isinstance(buffer.checksum if buffer.checksum else 'NA', str))
        assert(isinstance(buffer.headers if buffer.headers else [], list))
        for h in buffer.headers:
            assert(isinstance(h if h else 'NA', str))
        

        assert(isinstance(buffer.key if buffer.key else 'NA', str))
        assert(isinstance(buffer.offset if buffer.offset else 0, int))
        assert(isinstance(buffer.partition if buffer.partition else 0, int))
        assert(isinstance(buffer.serialized_key_size if buffer.serialized_key_size else 0, int))
        assert(isinstance(buffer.serialized_value_size if buffer.serialized_value_size else 0, int))
        assert(isinstance(buffer.timestamp if buffer.timestamp else 0, int))
        assert(isinstance(datetime.datetime.fromtimestamp(buffer.timestamp / 1000), datetime.datetime))
        assert(isinstance(buffer.timestamp_type if buffer.timestamp_type else 0, int))
        assert(isinstance(buffer.topic if buffer.topic else 'NA', str))
        assert(isinstance(buffer._is_protocol if buffer._is_protocol else False, bool))

        return f(*args, **kwargs)
    
    return wrapper

def validate_log(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        parser, log = args
        assert('level' in log and isinstance(log['level'] if log['level'] else 'NA', str))
        assert('timestamp' in log and isinstance(log['timestamp'] if log['timestamp'] else 'NA', str))
        assert(isinstance(datetime.datetime.strptime(log['timestamp'], '%Y-%m-%dT%H:%M:%S.%f'), datetime.datetime))
        assert('name' in log and isinstance(log['name'] if log['name'] else 'NA', str))
        assert('log_message' in log and isinstance(log['log_message'] if log['log_message'] else 'NA', str))

        return f(*args, **kwargs)
    
    return wrapper

def validate_lib_server_lobby(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        parser, log, task = args
        if log['log_message'] == 'Attack Completed':
            assert(isinstance(task, dict))
            if not 'PAYLOAD' in task:
                raise KeyError('Payload missing from task object')
        
            assert(isinstance(task['PAYLOAD'], dict))
            if not 'PARTICIPANTS_HEROS' in task['PAYLOAD']:
                raise KeyError('Participants Heros missing from task payload object')

            assert(isinstance(task['PAYLOAD']['PARTICIPANTS_HEROS'], dict))
            assert('TIMESTAMP' in task and isinstance(task['TIMESTAMP'] if task['TIMESTAMP'] else 'NA', str))
            assert(isinstance(datetime.datetime.strptime(task['TIMESTAMP'], '%Y-%m-%dT%H:%M:%SZ'), datetime.datetime))
            assert(
                'GAME_TOKEN' in task['PAYLOAD']['GAME_TOKEN'] and \
                isinstance(task['PAYLOAD']['GAME_TOKEN'] if task['PAYLOAD']['GAME_TOKEN'] else 'NA', str))
        
            participants = task['PAYLOAD']['PARTICIPANTS_HEROS']
            for k,v in participants.items():
                assert(isinstance(k if k else 'NA', str))
                assert('id' in v and isinstance(v['id'] if v['id'] else 0, int))
                assert('attack' in v and isinstance(v['attack'] if v['attack'] else 0, int))
                assert('health' in v and isinstance(v['health'] if v['health'] else 0, int))
        
        return f(*args, **kwargs)
    
    return wrapper

def validate_lib_server_game(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        parser, log, task = args
        if log['log_message'] == 'Attack Completed':
            assert(isinstance(task, dict))
            if not 'PAYLOAD' in task:
                raise KeyError('Payload missing from task object')
        
            if not 'STATUS' in task:
                raise KeyError('Status missing from task object')
        
            if not 'DETAILS' in task['STATUS']:
                raise KeyError('Details missing from task\'s Status object')
        
            assert('TIMESTAMP' in task and isinstance(task['TIMESTAMP'] if task['TIMESTAMP'] else 'NA', str))
            assert(isinstance(datetime.datetime.strptime(task['TIMESTAMP'], '%Y-%m-%dT%H:%M:%SZ'), datetime.datetime))
            assert(
                'GAME_TOKEN' in task['PAYLOAD'] and \
                isinstance(task['PAYLOAD']['GAME_TOKEN'] if task['PAYLOAD']['GAME_TOKEN'] else 'NA', str))
            assert(
                'USER_TOKEN' in task['PAYLOAD'] and \
                isinstance(task['PAYLOAD']['USER_TOKEN'] if task['PAYLOAD']['USER_TOKEN'] else 'NA', str))
            assert(
                'ACTION' in task['STATUS'] and \
                isinstance(task['STATUS']['ACTION'] if task['STATUS']['ACTION'] else 'NA', str))
            assert(
                'ENEMY_TOKEN' in task['STATUS']['DETAILS'] and \
                isinstance(task['STATUS']['DETAILS']['ENEMY_TOKEN'] if task['STATUS']['DETAILS']['ENEMY_TOKEN'] else 'NA', str))
            assert(
                'ENEMY_DAMAGE' in task['STATUS']['DETAILS'] and \
                isinstance(task['STATUS']['DETAILS']['ENEMY_DAMAGE'] if task['STATUS']['DETAILS']['ENEMY_DAMAGE'] else 0, int))
            assert(
                'ENEMY_HEALTH_PRIOR' in task['STATUS']['DETAILS'] and \
                isinstance(task['STATUS']['DETAILS']['ENEMY_HEALTH_PRIOR'] if task['STATUS']['DETAILS']['ENEMY_HEALTH_PRIOR'] else 0, int))
            assert(
                'ENEMY_HEALTH_POST' in task['STATUS']['DETAILS'] and \
                isinstance(task['STATUS']['DETAILS']['ENEMY_HEALTH_POST'] if task['STATUS']['DETAILS']['ENEMY_HEALTH_POST'] else 0, int))

        return f(*args, **kwargs)
    
    return wrapper


class ETL_Client:
    etl=[]
    buffers=[]
    logs=[]
    tasks=[]
    etl_id=str(uuid.uuid4())

    @property
    def start_time(self):
        return self._start_time
    
    @start_time.setter
    def start_time(self, start_time):
        self._start_time = start_time

    @property
    def end_time(self):
        return self._start_time
    
    @end_time.setter
    def end_time(self, end_time):
        self._end_time = end_time
    
    @property
    def msg_id(self):
        return self._msg_id
    
    def generate_msg_id(self):
        self._msg_id = str(uuid.uuid4())
    
    def clean(self):
        self.etl=[]
        self.buffers=[]
        self.logs=[]
        self.tasks=[]
        self._etl_id = str(uuid.uuid4())

    def extract(self, msg):
        log = json.loads(msg.value.decode('utf8'))
        if isinstance(log['task'], str):
            task = json.loads(log['task'])
        else:
            task = log['task']
        
        return msg, log, task
    
    @validate_log
    def transform_log(self, log):
        self.logs.extend([{
            'etl_id': self.etl_id,
            'msg_id': self.msg_id,
            'level': log['level'],
            'timestamp': log['timestamp'],
            'name': log['name'],
            'log_message': log['log_message'],
        }])
    
    @validate_buffer
    def transform_buffer(self, msg):
        self.buffers.extend([{
            'etl_id': self.etl_id,
            'msg_id': self.msg_id,
            'checksum': msg.checksum,
            'headers': msg.headers,
            'key': msg.key,
            'offset': msg.offset,
            'partition': msg.partition,
            'serialized_key_size': msg.serialized_key_size,
            'serialized_value_size': msg.serialized_value_size,
            'timestamp': datetime.datetime.fromtimestamp(msg.timestamp / 1000).strftime('%Y-%m-%dT%H:%M:%S.%f'),
            'timestamp_type': msg.timestamp_type,
            'topic': msg.topic,
            '_is_protocol': msg._is_protocol,
        }])
    
    def transform_etl(self):
        self.etl.append({
            'etl_id': self.etl_id,
            'service': 'Kafka',
            'mode': 'Batch',
            'timestamp_start': self._start_time.strftime('%Y-%m-%dT%H:%M:%S.%f'),
            'timestamp_end': self._end_time.strftime('%Y-%m-%dT%H:%M:%S.%f')
        })

    def load_parquet(self, data, schema, schema_name):
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

        partition_path = os.path.join(OUTPUT_DIR, 'raw', schema_name, datetime.date.today().strftime('%Y/%m/%d'))
        if not os.path.isdir(partition_path):
            os.makedirs(partition_path)
        
        ts = int(datetime.datetime.timestamp(datetime.datetime.now()) * 1000000)
        file_path = os.path.join(partition_path, '%s_%d.parquet.gz' % (self.etl_id, ts))
        pq.write_table(
            tbl,
            where=file_path,
            filesystem=filesystem,
            compression='gzip'
        )
    
    def load_json(self, data, schema_name):
        partition_path = os.path.join(OUTPUT_DIR, 'raw', schema_name, datetime.date.today().strftime('%Y/%m/%d'))
        if OUTPUT_FS  == 'LOCAL' and not os.path.isdir(partition_path):
            os.makedirs(partition_path)

        ts = int(datetime.datetime.timestamp(datetime.datetime.now()) * 1000000)
        file_path = os.path.join(partition_path, '%s_%d.json.gzip' % (self.etl_id, ts))

        with filesystem.open(file_path, 'w', compression='gzip') as f:
            json.dump(data, f)

class ETL_Lib_Server_Lobby(ETL_Client):
    
    @validate_lib_server_lobby
    def transform(self, log, task):
        if log['log_message'] == 'Starting Match':
            participants = task['PAYLOAD']['PARTICIPANTS_HEROS']
            self.tasks.extend([{
                'etl_id': self.etl_id,
                'msg_id': self.msg_id,
                'timestamp': datetime.datetime.strptime(task['TIMESTAMP'], '%Y-%m-%dT%H:%M:%SZ').strftime('%Y-%m-%dT%H:%M:%S.%f'),
                'game_token': task['PAYLOAD']['GAME_TOKEN'],
                'user_token': k,
                'superhero_id': v['id'],
                'superhero_attack': v['attack'],
                'superhero_health': v['health'],
            } for k,v in participants.items()])

class ETL_Lib_Server_Game(ETL_Client):
    
    @validate_lib_server_game
    def transform(self, log, task):
        if log['log_message'] == 'Attack Completed':
            self.tasks.extend([{
                'etl_id': self.etl_id,
                'msg_id': self.msg_id,
                'timestamp': datetime.datetime.strptime(task['TIMESTAMP'], '%Y-%m-%dT%H:%M:%SZ').strftime('%Y-%m-%dT%H:%M:%S.%f'),
                'game_token': task['PAYLOAD']['GAME_TOKEN'],
                'user_token': task['PAYLOAD']['USER_TOKEN'],
                'action': task['STATUS']['ACTION'],
                'enemy_token': task['STATUS']['DETAILS']['ENEMY_TOKEN'],
                'enemy_damage': task['STATUS']['DETAILS']['ENEMY_DAMAGE'],
                'enemy_health_prior': task['STATUS']['DETAILS']['ENEMY_HEALTH_PRIOR'],
                'enemy_health_post': task['STATUS']['DETAILS']['ENEMY_HEALTH_POST'],
            }])
    
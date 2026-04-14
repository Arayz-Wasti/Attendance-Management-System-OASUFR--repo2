from datetime import datetime
import redis
from django.http import JsonResponse

from OASUFR import settings

# Initialize Redis connection
hostname = settings.REDIS_HOST
port_number = settings.REDIS_PORT
password = settings.REDIS_PASSWORD

redis_client = redis.StrictRedis(host=hostname, port=port_number)


def get_all_redis_data(request):
    try:
        keys = redis_client.keys('*')
        all_data = {}

        for key in keys:
            key = key.decode(errors='replace')
            key_type = redis_client.type(key).decode()

            if key == 'attendance:logs' and key_type == 'list':
                logs = redis_client.lrange(key, 0, -1)
                unique_attendance = set()
                unique_logs = []

                logs = logs[::-1]

                for log in logs:
                    log = log.decode(errors='replace')
                    parts = log.split(' ')
                    person_name = parts[0]
                    timestamp = parts[-2] + ' ' + parts[-1]

                    date = datetime.fromisoformat(timestamp).date()
                    if date.strftime('%A') == 'Sunday':
                        continue

                    unique_key = (person_name, date)

                    if unique_key not in unique_attendance:
                        unique_attendance.add(unique_key)
                        unique_logs.append(log)

                all_data['attendance'] = unique_logs

            elif key == 'academy:register' and key_type == 'hash':
                value = redis_client.hgetall(key)
                structured_data = {}

                for k, v in value.items():
                    field = k.decode(errors='replace')
                    person_name, role = field.split('@')
                    structured_data[person_name] = role

                all_data['academy'] = structured_data

        return all_data
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

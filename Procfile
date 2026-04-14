web: gunicorn OASUFR.wsgi:application --log-file -
worker: celery -A OASUFR worker --loglevel=info --time-limit=3600 --soft-time-limit=300
beat: celery -A OASUFR beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler

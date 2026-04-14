import os
from celery import Celery
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'OASUFR.settings')

app = Celery('OASUFR')
app.conf.enable_utc = False

app.config_from_object(settings, namespace='CELERY')

app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f"Request: {self.request!r}")

# import os
# from datetime import timedelta
#
# from celery import Celery
#
# from OASUFR import settings
#
# os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'OASUFR.settings')
#
# __all__ = ("celery",)
#
# celery = Celery(
#     __name__,
#     broker=settings.CELERY_BROKER_URL,
#     backend=settings.CELERY_RESULT_BACKEND,
#     broker_connection_retry_on_startup=True
# )
#
# # celery.conf.imports = ["app.tasks"]
# celery.autodiscover_tasks()
#
# celery.conf.beat_schedule = {
#     "five-minute-of-next-day": {
#         "task": "app.tasks.add_attendance_sheet",
#         "schedule": 30.0
#         # "schedule": timedelta(hours=00, minutes=5),
#     },
#     "every-minute": {
#         "task": "app.tasks.mark_attendance_sheet",
#         "schedule": 30.0
#     },
# }
#
# celery.conf.timezone = "UTC"

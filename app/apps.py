from django.apps import AppConfig


class AppConfig(AppConfig):
    name = 'app'
    default_auto_field = 'django.db.models.BigAutoField'

    def ready(self):
        # Defer model access until all apps are fully loaded
        from django.db.models.signals import post_migrate
        from django_celery_beat.models import PeriodicTask

        def update_periodic_task(sender, **kwargs):
            """
            This method will run after migrations are applied and apps are ready.
            It updates the `last_run_at` field of all PeriodicTasks.
            """
            try:
                print("Updating PeriodicTask last_run_at field...")
                PeriodicTask.objects.all().update(last_run_at=None)
            except Exception as e:
                print(f"Error during setup of periodic tasks: {e}")

        # Connect the function to post_migrate signal
        post_migrate.connect(update_periodic_task)

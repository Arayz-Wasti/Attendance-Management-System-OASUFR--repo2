from celery import shared_task
from datetime import datetime, timedelta
from django.http import request
from django.utils.timezone import make_aware, get_current_timezone
from .models import Attendance
from .redis import get_all_redis_data

current_timezone = get_current_timezone()


@shared_task
def add_attendance_sheet():
    try:
        now_time = make_aware(datetime.now(), timezone=current_timezone)

        if now_time.strftime('%A') != 'Sunday':
            academy_data = get_all_redis_data(request).get('academy')
            if not academy_data:
                print("No academy data found.")
                return

            for name, role in academy_data.items():
                try:
                    if Attendance.objects.filter(name=name, role=role, date=now_time.date(), is_deleted=False).exists():
                        print(f"Duplicate attendance found for {name} ({role}) on {now_time.date()}. Skipping.")
                        continue

                    attendance = Attendance.objects.create(
                        name=name,
                        role=role,
                        date=now_time.date(),
                        day=now_time.strftime('%A'),
                        fine=500,
                        is_paid=False,
                        is_deleted=False
                    )
                    attendance.save()
                    print(f"Attendance for {name} ({role}) added successfully.")

                except Exception as inner_e:
                    print(f"Error processing attendance for {name} ({role}): {inner_e}")
        else:
            print("It's Sunday. Skipping attendance for today.")
    except Exception as e:
        print(f"Error in add_attendance_sheet task: {e}")


@shared_task
def mark_attendance_sheet():
    try:
        now_time = make_aware(datetime.now(), timezone=current_timezone)
        current_date = now_time.date()
        time_str = current_date.strftime('%Y-%m-%d %H:%M:%S.%f')
        first_5_minutes = make_aware(datetime.strptime(time_str, '%Y-%m-%d %H:%M:%S.%f'),
                                     timezone=current_timezone) + timedelta(minutes=5)

        if now_time.strftime('%A') != 'Sunday':
            attendance_data = get_all_redis_data(request).get('attendance')
            if not attendance_data:
                print("No attendance data found.")
                return

            attendance_list = attendance_data

            for entry in attendance_list:
                try:
                    parts = entry.split(" marked at ")
                    name_role = parts[0].strip()
                    timestamp_str = parts[1].strip()

                    name, role = name_role.split(" is ")
                    role = role.split(" ")[0]
                    timestamp = make_aware(datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S.%f'),
                                           timezone=current_timezone)
                    timestamp = timestamp

                    print(f"Parsed timestamp: {timestamp}, first_5_minutes: {first_5_minutes}, Now: {now_time}")

                    if not (first_5_minutes <= timestamp <= now_time):
                        print(f"Skipping entry outside the last hour: {entry}")
                        continue

                    attendance_record = Attendance.objects.filter(
                        name=name, role=role, date=timestamp.date(), is_deleted=False
                    ).first()

                    if attendance_record:
                        if not attendance_record.timestamp:
                            attendance_record.timestamp = timestamp
                            attendance_record.fine = 0
                            attendance_record.is_paid = True
                            attendance_record.save()
                            print(f"Updated attendance for {name} ({role}): Set timestamp and fine to 0.")
                        else:
                            print(f"Duplicate found. Skipping attendance for {name} ({role}) at {timestamp}.")
                        continue

                    print(f"Attendance for {name} ({role}) at {timestamp} added.")

                except Exception as e:
                    print(f"Error processing entry {entry}: {e}")
        else:
            print("It's Sunday. Skipping attendance for today.")

    except Exception as e:
        print(f"Error in mark_attendance_sheet task: {e}")

from collections import defaultdict

from datetime import date
from django.core.mail import send_mail
from django.contrib.auth.decorators import login_required
from django.urls import reverse
from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib.auth.views import LoginView, LogoutView
from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.urls import reverse_lazy
from django.utils.decorators import method_decorator
from django.views.generic import TemplateView, FormView
from django.core.paginator import Paginator
from OASUFR import settings
from app import models
from app.decorators import superuser_required, self_required
from app.redis import get_all_redis_data
from django.db.models import Q, Sum
from datetime import datetime, timedelta
from app.forms import LoginForm
import stripe
from django.db import transaction

from app.utils import add_attendance_sheet, mark_attendance_sheet

stripe.api_key = settings.STRIPE_SECRET_KEY
today = date.today()


def show_dashboard(request):
    try:
        data = get_all_redis_data(request)

        total_students = sum(1 for name, role in data["academy"].items() if role == "Student")
        total_teachers = sum(1 for name, role in data["academy"].items() if role == "Teacher")

        total_logs = len(data["attendance"])

        student_attendance_count = {}
        teacher_attendance_count = {}

        for key, value in data["academy"].items():
            name = key.strip()
            role = value.strip()

            if role == "Student":
                student_attendance_count[name] = role
            elif role == "Teacher":
                teacher_attendance_count[name] = role

        today = datetime.now()
        last_15_days = [(today - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(14, -1, -1)]

        daily_student_attendance = defaultdict(int)
        daily_teacher_attendance = defaultdict(int)

        for record in data["attendance"]:
            try:
                parts = record.split(" and marked at ")
                role_part = parts[0]
                timestamp_part = parts[1]

                name_and_role = role_part.split(" is ")
                role = name_and_role[1].strip()
                timestamp = datetime.strptime(timestamp_part, "%Y-%m-%d %H:%M:%S.%f")
                date = timestamp.strftime("%Y-%m-%d")

                if role == "Student":
                    daily_student_attendance[date] += 1
                elif role == "Teacher":
                    daily_teacher_attendance[date] += 1
            except (IndexError, ValueError):
                continue

        student_attendance = [daily_student_attendance[date] for date in last_15_days]
        teacher_attendance = [daily_teacher_attendance[date] for date in last_15_days]

        student_name = request.GET.get('student_name', '')
        teacher_name = request.GET.get('teacher_name', '')

        student_attendance_sorted = sorted(student_attendance_count.items())
        if student_attendance_sorted and student_name:
            student_attendance_sorted = [
                (name, count) for name, count in student_attendance_sorted if student_name.lower() in name.lower()
            ]
        student_list = [[] for _ in range(student_attendance_sorted.__len__())]

        for student in student_attendance_sorted:
            index = student_attendance_sorted.index(student)
            attendance_record = models.Attendance.objects.filter(name=student[0], role=student[1])
            total_fine = 0
            attendance_count = 0
            for data in attendance_record:
                if data.date == today.date():
                    pass
                else:
                    if not data.is_paid:
                        total_fine += data.fine
                if data.timestamp:
                    attendance_count += 1
            student_list[index].append(student[0])
            student_list[index].append(attendance_count)
            student_list[index].append(total_fine)

        teacher_attendance_sorted = sorted(teacher_attendance_count.items())
        if teacher_attendance_sorted and teacher_name:
            teacher_attendance_sorted = [
                (name, count) for name, count in teacher_attendance_sorted if teacher_name.lower() in name.lower()
            ]
        teacher_list = [[] for _ in range(teacher_attendance_sorted.__len__())]

        for teacher in teacher_attendance_sorted:
            index = teacher_attendance_sorted.index(teacher)
            attendance_record = models.Attendance.objects.filter(name=teacher[0], role=teacher[1])
            total_fine = 0
            attendance_count = 0
            for data in attendance_record:
                if data.date == today.date():
                    pass
                else:
                    if not data.is_paid:
                        total_fine += data.fine
                if data.timestamp:
                    attendance_count += 1
            teacher_list[index].append(teacher[0])
            teacher_list[index].append(attendance_count)
            teacher_list[index].append(total_fine)

        student_paginator = Paginator(student_list, 5)
        teacher_paginator = Paginator(teacher_list, 5)

        student_page_number = request.GET.get('student_page', 1)
        teacher_page_number = request.GET.get('teacher_page', 1)

        student_attendance_paginated = student_paginator.get_page(student_page_number)
        teacher_attendance_paginated = teacher_paginator.get_page(teacher_page_number)

        name = None
        if request.user.is_authenticated:
            name = request.user.first_name + " " + request.user.last_name

        context = {
            'name': name,
            'student_name': student_name,
            'teacher_name': teacher_name,
            'total_students': total_students,
            'total_teachers': total_teachers,
            'total_logs': total_logs,
            'student_attendance': student_attendance_paginated,
            'teacher_attendance': teacher_attendance_paginated,
            'last_15_days_labels': last_15_days,
            'student_attendance_last_15_days': student_attendance,
            'teacher_attendance_last_15_days': teacher_attendance,
        }

        return render(request, 'app/dashboard.html', context)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@self_required
def show_specific_data(request, pk):
    attendance_data = models.Attendance.objects.filter(name=pk)

    # Handle case where no attendance exists
    if not attendance_data.exists():
        messages.warning(request, "No attendance records found for this user.")
        return render(request, 'app/attendance.html', {})

    def calculate_stats(logs):
        total_absent = logs.filter(
            timestamp__isnull=True
        ).exclude(date=str(today)).count()

        total_present = logs.filter(
            timestamp__isnull=False
        ).count()

        total_fine = (
            logs.filter(Q(is_paid=False) & Q(fine=500))
            .exclude(date=str(today))
            .aggregate(total_fine=Sum('fine'))['total_fine']
            or 0
        )

        # FIXED: Safe joining date fetch
        joining_record = logs.order_by('date').first()
        role = joining_record.role if joining_record else "N/A"
        joining_date_value = joining_record.date if joining_record else "N/A"

        absent_dates = (
            logs.filter(Q(is_paid=False) & Q(fine=500))
            .exclude(date=str(today))
            .values_list('date', flat=True)
            .order_by('date')
        )

        paid_fines = (
            logs.filter(Q(is_paid=True) & Q(fine=500))
            .exclude(date=str(today))
            .values_list('date', flat=True)
            .order_by('date')
        )

        # Pagination
        absent_paginator = Paginator(absent_dates, 5)
        paid_paginator = Paginator(paid_fines, 5)

        absent_page = request.GET.get('absent_page', 1)
        paid_page = request.GET.get('fine_paid_page', 1)

        return {
            'name': pk,
            'role': role,
            'total_absent': total_absent,
            'total_present': total_present,
            'total_fine': total_fine,
            'absent_dates': absent_paginator.get_page(absent_page),
            'paid_fines': paid_paginator.get_page(paid_page),
            'joining_date': joining_date_value,
            'status': 'Defaulter' if total_fine else 'Eligible'
        }

    attendance_stats = calculate_stats(attendance_data)

    # ---------------- EMAIL REPORT ---------------- #
    if request.method == 'POST':
        email = request.POST.get('email')

        if not email:
            messages.error(request, "Please provide a valid email address.")
            return redirect(request.path)

        absent_dates_formatted = "\n".join(
            [f"- {date}: 500" for date in attendance_stats['absent_dates']]
        ) or "None"

        paid_fines_formatted = "\n".join(
            [f"- {date}: 500" for date in attendance_stats['paid_fines']]
        ) or "None"

        report_content = (
            f"Attendance Report for {attendance_stats['name']} ({attendance_stats['role']}):\n\n"
            f"Total Present: {attendance_stats['total_present']}\n"
            f"Total Absent: {attendance_stats['total_absent']}\n"
            f"Total Fine: {attendance_stats['total_fine']}\n\n"
            f"Absent Dates:\n{absent_dates_formatted}\n\n"
            f"Paid Fines:\n{paid_fines_formatted}\n\n"
            f"Joining Date: {attendance_stats['joining_date']}\n"
            f"Status: {attendance_stats['status']}\n\n"
            f"Report Generated On: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            f"Please clear your dues to avoid inconvenience.\n"
        )

        try:
            send_mail(
                subject=f"Attendance Report - {attendance_stats['name']}",
                message=report_content,
                from_email="no-reply@oasufr.com",
                recipient_list=[email],
                fail_silently=False,
            )
            messages.success(request, f"Attendance report sent to {email}.")
        except Exception as e:
            messages.error(request, f"Email sending failed: {str(e)}")

    return render(
        request,
        'app/attendance.html',
        {'attendance_stats': attendance_stats}
    )


@login_required
@superuser_required
def show_logs(request):
    try:
        target_date_str = request.GET.get('day') or request.GET.get('date')
        search_query = request.GET.get('search', '')
        if request.method == 'POST':
            fine_id = request.POST.get('fine_id')
            fine_amount = request.POST.get('fine_amount')
            attendance_record = models.Attendance.objects.get(id=int(fine_id))
            if attendance_record:
                if int(attendance_record.fine) == int(fine_amount):
                    attendance_record.is_paid = True
                    attendance_record.save()

            models.FinePayment.objects.create(attendance=attendance_record,
                                              payer_name=request.user.username,
                                              payer_email=request.user.email,
                                              amount=int(fine_amount),
                                              cardholder_name="Manual Payment",
                                              payment_intent_id="Cash")

            messages.success(request, f'Payment was successful for absent fine.')
            messages.success(request, f'Role: {attendance_record.role}')
            messages.success(request, f'Name: {attendance_record.name}')
            messages.success(request, f'Date: {attendance_record.date}')
            target_date_str = request.POST.get('day') or request.POST.get('date')
            search_query = request.POST.get('search', '')

        if target_date_str:
            try:
                target_date = datetime.strptime(target_date_str, "%Y-%m-%d").date()
            except ValueError:
                target_date = datetime.today().date()
        else:
            target_date = datetime.today().date()

        if target_date == datetime.today().date():
            mark_attendance_sheet()

        attendance_logs = (models.Attendance.objects.filter(date=target_date))
        attendance_logs = attendance_logs.order_by('name')

        if not attendance_logs and target_date == datetime.today().date():
            add_attendance_sheet()

        if target_date == datetime.today().date():
            for attendance in attendance_logs:
                attendance.fine = 1

        if search_query:
            attendance_logs = attendance_logs.filter(
                Q(name__icontains=search_query) | Q(role__icontains=search_query)
            )

        context = {
            'attendance_logs': attendance_logs,
            'target_date': target_date or datetime.today().date(),
            'search_query': search_query
        }

        return render(request, 'app/logs.html', context)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


class Login(LoginView):
    template_name = 'app/login.html'
    authentication_form = LoginForm

    def get_success_url(self):
        return self.request.POST.get('next') or reverse_lazy('dashboard')

    def form_invalid(self, form):
        messages.add_message(self.request, messages.ERROR, "Invalid credentials. Please try again.")
        return super().form_invalid(form)


class Logout(LoginRequiredMixin, LogoutView):
    template_name = 'app/login.html'

    def get_success_url(self):
        return reverse_lazy('dashboard')


@method_decorator(login_required, name='dispatch')
class StripeInfoHide(LoginRequiredMixin, FormView):
    template_name = 'app/stripe.html'

    @transaction.atomic
    def post(self, request, *args, **kwargs):
        fine_id = self.request.POST.get('fine_id')
        allow_return = "False"
        if not fine_id:
            name_pk = self.request.POST.get('name_pk')
            date_pk = self.request.POST.get('date_pk')
            date_obj = (datetime.strptime
                        (date_pk, "%b. %d, %Y"))
            formatted_date = date_obj.strftime("%Y-%m-%d")
            record = models.Attendance.objects.get(name=name_pk, date=formatted_date)
            allow_return = "True"
            fine_id = record.id
        search_query = self.request.POST.get('search_query')
        date = self.request.POST.get('date')
        amount = self.request.POST.get('fine_amount')
        total_amount = int(amount) * 100

        intent = stripe.PaymentIntent.create(
            amount=total_amount,
            currency='usd',
            receipt_email=request.user.email,
            payment_method_types=['card']
        )

        context = {}
        context['client_secret'] = intent.client_secret
        context['STRIPE_PUBLISHABLE_KEY'] = settings.STRIPE_PUBLISHABLE_KEY
        context['payment_intent_id'] = intent.id
        context['fine_amount'] = amount
        context['fine_id'] = fine_id
        context['date'] = date
        context['allow_return'] = allow_return
        context['search_query'] = search_query

        return render(request, 'app/stripe.html', context)


@method_decorator(login_required, name='dispatch')
class StripeSuccess(LoginRequiredMixin, TemplateView):
    template_name = 'app/stripe.html'

    @transaction.atomic
    def post(self, request, *args, **kwargs):
        card_holder_name = self.request.POST.get('card_holder_name')
        payment_intent_id = self.request.POST.get('payment_intent_id')
        fine_id = self.request.POST.get('fine_id')
        fine_amount = self.request.POST.get('fine_amount')
        allow_return = self.request.POST.get('allow_return')
        search = self.request.POST.get('search_query')
        date = self.request.POST.get('date')

        try:
            attendance_record = models.Attendance.objects.get(id=int(fine_id))
            if attendance_record:
                if int(attendance_record.fine) == int(fine_amount):
                    attendance_record.is_paid = True
                    attendance_record.save()

                models.FinePayment.objects.create(attendance=attendance_record,
                                                  payer_name=request.user.username,
                                                  payer_email=request.user.email,
                                                  amount=int(fine_amount),
                                                  cardholder_name=card_holder_name,
                                                  payment_intent_id=payment_intent_id)

                messages.success(request, f'Payment was successful for absent fine.')
                messages.success(request, f'Role: {attendance_record.role}')
                messages.success(request, f'Name: {attendance_record.name}')
                messages.success(request, f'Date: {attendance_record.date}')
                if allow_return == "True":
                    url = reverse('attendance', args=[attendance_record.name])
                    return redirect(url)
                url = reverse('logs') + f'?search_query={search}&date={date}'
                return redirect(url)
        except Exception as e:
            messages.error(request, 'Payment was not successful.', str(e))
            return redirect('logs')

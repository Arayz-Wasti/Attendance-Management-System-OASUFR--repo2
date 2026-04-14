from django.contrib import admin
from app.models import Attendance, FinePayment


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ('name', 'role', 'timestamp', 'fine', 'date', 'day', 'is_deleted', 'created_at', 'updated_at')
    search_fields = ('name', 'role', 'date', 'day')
    list_filter = ('role', 'date', 'day', 'is_deleted')
    ordering = ('-created_at',)


@admin.register(FinePayment)
class FinePaymentAdmin(admin.ModelAdmin):
    list_display = ('id', 'attendance', 'payer_name', 'payer_email', 'amount', 'cardholder_name', 'payment_intent_id',
                    'payment_date')
    search_fields = ('attendance', 'payment_intent_id', 'payment_date')
    list_filter = ('payer_name', 'payment_date')
    ordering = ('-payment_date',)

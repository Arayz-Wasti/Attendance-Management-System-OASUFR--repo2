from django.db import models


class Attendance(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=50)
    role = models.CharField(max_length=50)
    timestamp = models.DateTimeField(null=True, blank=True)
    fine = models.IntegerField(null=True, blank=True)
    date = models.DateField()
    day = models.CharField(max_length=10, null=True, blank=True)
    is_paid = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class FinePayment(models.Model):
    attendance = models.ForeignKey(Attendance, on_delete=models.PROTECT, editable=False)
    payer_name = models.CharField(max_length=255, editable=False)
    payer_email = models.EmailField(editable=False)
    amount = models.IntegerField(editable=False)
    cardholder_name = models.CharField(max_length=255, editable=False)
    payment_intent_id = models.CharField(max_length=255, editable=False)
    payment_date = models.DateField(auto_now_add=True, editable=False)

    def __str__(self):
        return self.attendance.name

"""
payments/models.py — Payment Model

Matches Railway Postgres `payments` table schema exactly.
"""
import uuid
from django.db import models


class Payment(models.Model):
    """
    Payment model matching Railway's `payments` table.

    PK: payment_id (UUID)
    Table: payments
    Content type: payments.payment
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]

    METHOD_CHOICES = [
        ('upi', 'UPI'),
        ('card', 'Card'),
        ('netbanking', 'Net Banking'),
        ('cash', 'Cash'),
    ]

    payment_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    hostel = models.ForeignKey(
        'hostels.Hostel',
        on_delete=models.CASCADE,
        related_name='payments',
        db_column='hostel_id',
    )
    booking = models.ForeignKey(
        'bookings.Booking',
        on_delete=models.CASCADE,
        related_name='payments',
        db_column='booking_id',
    )
    user_name = models.CharField(max_length=255)
    room_name = models.CharField(max_length=100)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    method = models.CharField(max_length=20, choices=METHOD_CHOICES, default='upi')
    transaction_ref = models.CharField(max_length=100, null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payments'
        ordering = ['-created_at']

    def __str__(self):
        return f'Payment {self.payment_id} — {self.user_name} ({self.status})'

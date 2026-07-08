"""
bookings/models.py — Booking Model

Matches Railway Postgres `bookings` table schema exactly.
Uses UUID primary key (booking_id).
Note: Railway's bookings table uses denormalized user fields instead of a FK.
"""
import uuid
from django.db import models


class Booking(models.Model):
    """
    Booking model matching Railway's `bookings` table.

    PK: booking_id (UUID)
    Table: bookings
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]

    booking_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Denormalized user fields (Railway does NOT use a FK to owners)
    user_id = models.CharField(max_length=255)
    user_name = models.CharField(max_length=255)
    user_email = models.EmailField(max_length=254)
    user_phone = models.CharField(max_length=20)
    user_profile_photo = models.CharField(max_length=200, null=True, blank=True)

    # Room info
    room_name = models.CharField(max_length=100)

    # FK references
    hostel = models.ForeignKey(
        'hostels.Hostel',
        on_delete=models.CASCADE,
        related_name='hostel_bookings',
        db_column='hostel_id',
    )
    room = models.ForeignKey(
        'rooms.Room',
        on_delete=models.CASCADE,
        related_name='bookings',
        db_column='room_id',
    )

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    check_in_date = models.DateField()
    check_out_date = models.DateField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)

    requested_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'bookings'
        ordering = ['-requested_at']

    def __str__(self):
        return f'Booking {self.booking_id} — {self.user_name} @ {self.hostel.name}'

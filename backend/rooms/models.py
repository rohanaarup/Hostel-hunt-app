"""
rooms/models.py — Room Model

Matches Railway Postgres `rooms` table schema exactly.
Uses UUID primary key (room_id).
"""
import uuid
from django.db import models


class Room(models.Model):
    """
    Room model matching Railway's `rooms` table.

    PK: room_id (UUID)
    Table: rooms
    """
    room_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    hostel = models.ForeignKey(
        'hostels.Hostel',
        on_delete=models.CASCADE,
        related_name='rooms',
        db_column='hostel_id',
    )
    room_name = models.CharField(max_length=100)
    sharing_type = models.CharField(max_length=20)
    capacity = models.IntegerField(default=1)
    price_per_month = models.DecimalField(max_digits=10, decimal_places=2)
    available_beds = models.IntegerField(default=0)
    has_attached_bathroom = models.BooleanField(default=False)
    is_ac = models.BooleanField(default=False)
    description = models.TextField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'rooms'
        ordering = ['room_name']

    def __str__(self):
        return f'{self.room_name} - {self.hostel.name}'

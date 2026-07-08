"""
hostels/models.py — Hostel Model

Matches Railway Postgres `hostels` table schema exactly.
Uses UUID primary key (hostel_id).
"""
import uuid
from django.db import models
from django.conf import settings


class Hostel(models.Model):
    """
    Hostel listing model matching Railway's `hostels` table.

    PK: hostel_id (UUID)
    Table: hostels
    """
    GENDER_TYPE_CHOICES = [
        ('boys', 'Boys'),
        ('girls', 'Girls'),
        ('mixed', 'Mixed / Co-ed'),
    ]

    hostel_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, db_index=True)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='hostels',
        db_column='owner_id',
    )
    owner_name = models.CharField(max_length=255)
    contact_number = models.CharField(max_length=20)
    email = models.EmailField(max_length=254)
    address = models.TextField()
    city = models.CharField(max_length=100, db_index=True)
    state = models.CharField(max_length=100)
    pincode = models.CharField(max_length=20)
    landmark = models.CharField(max_length=255, null=True, blank=True)

    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    google_maps_url = models.CharField(max_length=500, null=True, blank=True)

    gender_type = models.CharField(
        max_length=20,
        choices=GENDER_TYPE_CHOICES,
        default='mixed',
        db_index=True,
    )
    total_floors = models.IntegerField(default=1)
    total_rooms = models.IntegerField(default=1)
    total_beds = models.IntegerField(default=1)
    occupancy_types = models.JSONField(default=list)

    description = models.TextField(null=True, blank=True)
    rules = models.TextField(null=True, blank=True)
    check_in_policy = models.CharField(max_length=255, null=True, blank=True)
    check_out_policy = models.CharField(max_length=255, null=True, blank=True)

    amenities = models.JSONField(default=list)

    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'hostels'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} ({self.city})'

    @property
    def average_rating(self):
        # Placeholder — reviews table doesn't exist in Railway yet
        return 0.0

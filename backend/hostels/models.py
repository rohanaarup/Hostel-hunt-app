"""
hostels/models.py — Hostel Listing Model

Designed for scalability: supports filtering by city/type/price,
full-text search, and image attachments.
"""
from django.db import models
from django.conf import settings


class Hostel(models.Model):
    HOSTEL_TYPE_CHOICES = [
        ('boys', 'Boys'),
        ('girls', 'Girls'),
        ('mixed', 'Mixed / Co-ed'),
    ]

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='hostels',
    )
    name = models.CharField(max_length=200, db_index=True)
    description = models.TextField(blank=True)
    address = models.TextField()
    city = models.CharField(max_length=100, db_index=True)
    state = models.CharField(max_length=100, blank=True)
    pincode = models.CharField(max_length=10, blank=True)

    hostel_type = models.CharField(
        max_length=10,
        choices=HOSTEL_TYPE_CHOICES,
        default='mixed',
        db_index=True,
    )
    price_per_month = models.DecimalField(
        max_digits=8, decimal_places=2, db_index=True
    )
    security_deposit = models.DecimalField(
        max_digits=8, decimal_places=2, default=0
    )
    amenities = models.TextField(
        default='',
        blank=True,
        help_text='Comma-separated list of amenities: WiFi,AC,Meals,Parking',
    )
    total_rooms = models.PositiveSmallIntegerField(default=1)
    available_rooms = models.PositiveSmallIntegerField(default=1)
    is_available = models.BooleanField(default=True, db_index=True)

    # Location for future map/geo features
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )

    contact_phone = models.CharField(max_length=20, blank=True)
    contact_email = models.EmailField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['city', 'hostel_type']),
            models.Index(fields=['city', 'price_per_month']),
        ]

    def __str__(self):
        return f'{self.name} ({self.city})'

    @property
    def average_rating(self):
        reviews = self.reviews.all()
        if not reviews:
            return 0.0
        return round(sum(r.rating for r in reviews) / len(reviews), 1)


class HostelImage(models.Model):
    hostel = models.ForeignKey(Hostel, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='hostels/images/')
    caption = models.CharField(max_length=200, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Image for {self.hostel.name}'

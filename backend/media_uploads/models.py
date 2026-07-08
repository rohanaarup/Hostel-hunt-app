"""
media_uploads/models.py — Media Item Model

Matches Railway Postgres `media_items` table schema exactly.
"""
import uuid
from django.db import models


class MediaItem(models.Model):
    """
    Media file model matching Railway's `media_items` table.

    PK: id (UUID)
    Table: media_items
    Content type: media_uploads.mediaitem
    """
    CATEGORY_CHOICES = [
        ('photo', 'Photo'),
        ('video', 'Video'),
        ('document', 'Document'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    hostel = models.ForeignKey(
        'hostels.Hostel',
        on_delete=models.CASCADE,
        related_name='media_items',
        null=True,
        blank=True,
        db_column='hostel_id',
    )
    room = models.ForeignKey(
        'rooms.Room',
        on_delete=models.CASCADE,
        related_name='media_items',
        null=True,
        blank=True,
        db_column='room_id',
    )
    file = models.FileField(upload_to='media_uploads/', max_length=100)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='photo')
    mime_type = models.CharField(max_length=100)
    file_name = models.CharField(max_length=255)
    order_index = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'media_items'
        ordering = ['order_index']

    def __str__(self):
        return f'{self.file_name} ({self.category})'

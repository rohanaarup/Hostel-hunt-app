"""
favorites/models.py — User Favorites/Wishlist Models

Allows users to save hostels and rooms they're interested in
for quick access later without making a booking.
"""
from django.db import models
from django.conf import settings


class FavoriteHostel(models.Model):
    """
    User's saved/favorited hostels.
    Allows tracking which hostels a user is interested in.
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorite_hostels',
        help_text='User who saved this hostel',
    )
    hostel = models.ForeignKey(
        'hostels.Hostel',
        on_delete=models.CASCADE,
        related_name='favorited_by',
        help_text='Hostel that was favorited',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'hostel')  # Each user can favorite a hostel only once
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['hostel']),
        ]

    def __str__(self):
        return f'{self.user.email} ♥ {self.hostel.name}'


class FavoriteRoom(models.Model):
    """
    User's saved/favorited rooms.
    Allows tracking which specific rooms a user likes.
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorite_rooms',
        help_text='User who saved this room',
    )
    room = models.ForeignKey(
        'rooms.Room',
        on_delete=models.CASCADE,
        related_name='favorited_by',
        help_text='Room that was favorited',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'room')  # Each user can favorite a room only once
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['room']),
        ]

    def __str__(self):
        return f'{self.user.email} ♥ {self.room.room_name}'

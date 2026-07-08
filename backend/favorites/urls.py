"""favorites/urls.py"""
from django.urls import path
from .views import (
    FavoriteHostelListView,
    FavoriteHostelToggleView,
    FavoriteRoomListView,
    FavoriteRoomToggleView,
)

urlpatterns = [
    # Hostels
    path('hostels/', FavoriteHostelListView.as_view(), name='favorite-hostels'),
    path('hostels/<int:hostel_id>/toggle/', FavoriteHostelToggleView.as_view(), name='favorite-hostel-toggle'),

    # Rooms
    path('rooms/', FavoriteRoomListView.as_view(), name='favorite-rooms'),
    path('rooms/<int:room_id>/toggle/', FavoriteRoomToggleView.as_view(), name='favorite-room-toggle'),
]

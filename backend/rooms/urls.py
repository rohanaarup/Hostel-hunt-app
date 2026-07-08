from django.urls import path
from .views import (
    RoomListView,
    RoomCreateView,
    RoomUpdateView,
    RoomDeleteView,
)

urlpatterns = [
    path('my-rooms/', RoomListView.as_view(), name='room-owner-list'),
    path('create/', RoomCreateView.as_view(), name='room-create'),
    path('<uuid:pk>/update/', RoomUpdateView.as_view(), name='room-update'),
    path('<uuid:pk>/delete/', RoomDeleteView.as_view(), name='room-delete'),
]

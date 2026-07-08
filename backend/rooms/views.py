from rest_framework.generics import (
    ListAPIView,
    CreateAPIView,
    UpdateAPIView,
    DestroyAPIView,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend

from .models import Room
from .serializers import (
    RoomListSerializer,
    RoomDetailSerializer,
    RoomCreateSerializer,
)
from accounts.permissions import IsOwner
from hostels.models import Hostel


class RoomCreateView(CreateAPIView):
    serializer_class = RoomCreateSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def perform_create(self, serializer):
        hostel = serializer.validated_data.get('hostel')
        
        if hostel.owner != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied(
                'You can only create rooms in your own hostels.'
            )
        
        serializer.save()


class RoomListView(ListAPIView):
    serializer_class = RoomListSerializer
    permission_classes = [IsAuthenticated, IsOwner]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['room_name', 'sharing_type', 'description']
    ordering_fields = ['price_per_month', 'capacity', 'created_at']
    ordering = ['room_name']
    
    def get_queryset(self):
        return (
            Room.objects
            .filter(hostel__owner=self.request.user)
            .select_related('hostel')
        )


class RoomUpdateView(UpdateAPIView):
    serializer_class = RoomDetailSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Room.objects.filter(hostel__owner=self.request.user)


class RoomDeleteView(DestroyAPIView):
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Room.objects.filter(hostel__owner=self.request.user)

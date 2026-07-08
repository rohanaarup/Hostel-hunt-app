from rest_framework.generics import (
    ListAPIView,
    RetrieveAPIView,
    CreateAPIView,
    UpdateAPIView,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q

from .models import Booking
from .serializers import (
    BookingListSerializer,
    BookingDetailSerializer,
    BookingCreateSerializer,
)
from accounts.permissions import IsOwner


class StudentBookingListView(ListAPIView):
    serializer_class = BookingListSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['status']
    ordering_fields = ['check_in_date', 'requested_at']
    ordering = ['-requested_at']

    def get_queryset(self):
        return (
            Booking.objects
            .filter(user_id=str(self.request.user.owner_id))
            .select_related('hostel', 'room')
        )


class BookingDetailView(RetrieveAPIView):
    serializer_class = BookingDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        
        if user.role == 'owner':
            return Booking.objects.filter(hostel__owner=user)
        else:
            return Booking.objects.filter(user_id=str(user.owner_id))


class BookingCreateView(CreateAPIView):
    serializer_class = BookingCreateSerializer
    permission_classes = [IsAuthenticated]


class OwnerBookingListView(ListAPIView):
    serializer_class = BookingListSerializer
    permission_classes = [IsAuthenticated, IsOwner]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['status', 'hostel']
    ordering_fields = ['check_in_date', 'requested_at']
    ordering = ['-requested_at']

    def get_queryset(self):
        return (
            Booking.objects
            .filter(hostel__owner=self.request.user)
            .select_related('hostel', 'room')
        )


class BookingStatusUpdateView(UpdateAPIView):
    serializer_class = BookingDetailSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Booking.objects.filter(hostel__owner=self.request.user)

    def perform_update(self, serializer):
        status = self.request.data.get('status')
        if status in dict(Booking.STATUS_CHOICES):
            serializer.save(status=status)
        else:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'status': 'Invalid status.'})

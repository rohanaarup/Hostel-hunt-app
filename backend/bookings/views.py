"""
bookings/views.py — Booking API Views

GET  /api/bookings/        — User's bookings (paginated)
POST /api/bookings/        — Create a booking
GET  /api/bookings/<id>/   — Booking detail
PATCH /api/bookings/<id>/  — Cancel a booking
"""
from rest_framework import status
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Booking
from .serializers import BookingSerializer, CreateBookingSerializer


class BookingListCreateView(ListCreateAPIView):
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Users can only see their own bookings
        return Booking.objects.filter(user=self.request.user).select_related('hostel')

    def get_serializer_class(self):
        return CreateBookingSerializer if self.request.method == 'POST' else BookingSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class BookingDetailView(RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = BookingSerializer
    http_method_names = ['get', 'patch']

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user)

    def partial_update(self, request, *args, **kwargs):
        """Only allow cancellation via PATCH."""
        booking = self.get_object()
        if booking.status in ('completed', 'cancelled'):
            return Response(
                {'success': False, 'message': f'Cannot modify a {booking.status} booking.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        booking.status = 'cancelled'
        booking.save(update_fields=['status'])
        return Response(BookingSerializer(booking).data)

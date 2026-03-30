"""
hostels/views.py — Hostel API Views

GET /api/hostels/        — Paginated list with filtering + search
GET /api/hostels/<id>/   — Hostel detail
"""
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.permissions import AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import Hostel
from .serializers import HostelListSerializer, HostelDetailSerializer
from .filters import HostelFilter


class HostelListView(ListAPIView):
    """
    Paginated hostel listings with filtering and search.

    Query params:
        city=           Filter by city (case-insensitive)
        hostel_type=    boys | girls | mixed
        min_price=      Minimum price per month
        max_price=      Maximum price per month
        is_available=   true | false
        search=         Full-text search on name, city, description
        ordering=       price_per_month | -price_per_month | created_at
    """
    queryset = Hostel.objects.prefetch_related('images', 'reviews').all()
    serializer_class = HostelListSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = HostelFilter
    search_fields = ['name', 'city', 'description', 'address']
    ordering_fields = ['price_per_month', 'created_at', 'available_rooms']
    ordering = ['-created_at']


class HostelDetailView(RetrieveAPIView):
    """Full hostel detail including all images and reviews."""
    queryset = Hostel.objects.prefetch_related('images', 'reviews').all()
    serializer_class = HostelDetailSerializer
    permission_classes = [AllowAny]

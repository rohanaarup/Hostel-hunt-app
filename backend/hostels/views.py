from rest_framework.generics import (
    ListAPIView,
    RetrieveAPIView,
    CreateAPIView,
    UpdateAPIView,
    DestroyAPIView,
)
from rest_framework.permissions import AllowAny, IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import Hostel
from .serializers import (
    HostelListSerializer,
    HostelDetailSerializer,
    HostelCreateSerializer,
)
from .filters import HostelFilter
from accounts.permissions import IsOwner


class HostelListView(ListAPIView):
    queryset = Hostel.objects.prefetch_related('media_items').filter(is_active=True)
    serializer_class = HostelListSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = HostelFilter
    search_fields = ['name', 'city', 'description', 'address', 'landmark']
    ordering_fields = ['created_at']
    ordering = ['-created_at']


class HostelDetailView(RetrieveAPIView):
    queryset = Hostel.objects.prefetch_related('media_items').all()
    serializer_class = HostelDetailSerializer
    permission_classes = [AllowAny]


class HostelOwnerListView(ListAPIView):
    serializer_class = HostelListSerializer
    permission_classes = [IsAuthenticated, IsOwner]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = HostelFilter
    search_fields = ['name', 'city', 'description', 'address', 'landmark']
    ordering_fields = ['created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        return (
            Hostel.objects
            .filter(owner=self.request.user)
            .prefetch_related('media_items')
        )


class HostelCreateView(CreateAPIView):
    queryset = Hostel.objects.all()
    serializer_class = HostelCreateSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class HostelUpdateView(UpdateAPIView):
    serializer_class = HostelCreateSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Hostel.objects.filter(owner=self.request.user)


class HostelDeleteView(DestroyAPIView):
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Hostel.objects.filter(owner=self.request.user)

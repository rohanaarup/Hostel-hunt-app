"""
reviews/views.py — Review API Views

GET  /api/reviews/?hostel=<id>  — Reviews for a hostel
POST /api/reviews/              — Create review (authenticated)
"""
from rest_framework.generics import ListCreateAPIView
from rest_framework.permissions import IsAuthenticated, AllowAny

from .models import Review
from .serializers import ReviewSerializer, CreateReviewSerializer


class ReviewListCreateView(ListCreateAPIView):

    def get_permissions(self):
        if self.request.method == 'GET':
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        qs = Review.objects.select_related('user', 'hostel')
        hostel_id = self.request.query_params.get('hostel')
        if hostel_id:
            qs = qs.filter(hostel_id=hostel_id)
        return qs

    def get_serializer_class(self):
        return CreateReviewSerializer if self.request.method == 'POST' else ReviewSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

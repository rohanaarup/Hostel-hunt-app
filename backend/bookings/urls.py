from django.urls import path
from .views import (
    StudentBookingListView,
    BookingDetailView,
    BookingCreateView,
    OwnerBookingListView,
    BookingStatusUpdateView,
)

urlpatterns = [
    # Student routes
    path('my-bookings/', StudentBookingListView.as_view(), name='student-bookings'),
    path('create/', BookingCreateView.as_view(), name='booking-create'),
    
    # Owner routes
    path('hostel-bookings/', OwnerBookingListView.as_view(), name='owner-bookings'),
    path('<uuid:pk>/update-status/', BookingStatusUpdateView.as_view(), name='booking-status-update'),
    
    # Shared
    path('<uuid:pk>/', BookingDetailView.as_view(), name='booking-detail'),
]

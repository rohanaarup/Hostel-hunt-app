from django.urls import path
from .views import (
    HostelListView,
    HostelDetailView,
    HostelCreateView,
    HostelOwnerListView,
    HostelUpdateView,
    HostelDeleteView,
)

urlpatterns = [
    path('', HostelListView.as_view(), name='hostel-list'),
    path('create/', HostelCreateView.as_view(), name='hostel-create'),
    path('my-hostels/', HostelOwnerListView.as_view(), name='hostel-owner-list'),
    path('<uuid:pk>/update/', HostelUpdateView.as_view(), name='hostel-update'),
    path('<uuid:pk>/delete/', HostelDeleteView.as_view(), name='hostel-delete'),
    path('<uuid:pk>/', HostelDetailView.as_view(), name='hostel-detail'),
]

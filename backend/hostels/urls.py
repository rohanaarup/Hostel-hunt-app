"""hostels/urls.py"""
from django.urls import path
from .views import HostelListView, HostelDetailView

urlpatterns = [
    path('', HostelListView.as_view(), name='hostel-list'),
    path('<int:pk>/', HostelDetailView.as_view(), name='hostel-detail'),
]

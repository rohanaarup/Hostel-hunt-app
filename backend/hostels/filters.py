"""
hostels/filters.py — Django-filter configuration for hostel listings
"""
import django_filters
from .models import Hostel


class HostelFilter(django_filters.FilterSet):
    city = django_filters.CharFilter(field_name='city', lookup_expr='icontains')
    hostel_type = django_filters.ChoiceFilter(choices=Hostel.HOSTEL_TYPE_CHOICES)
    min_price = django_filters.NumberFilter(field_name='price_per_month', lookup_expr='gte')
    max_price = django_filters.NumberFilter(field_name='price_per_month', lookup_expr='lte')
    is_available = django_filters.BooleanFilter(field_name='is_available')

    class Meta:
        model = Hostel
        fields = ['city', 'hostel_type', 'min_price', 'max_price', 'is_available']

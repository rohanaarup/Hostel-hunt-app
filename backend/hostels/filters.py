import django_filters
from .models import Hostel


class HostelFilter(django_filters.FilterSet):
    city = django_filters.CharFilter(field_name='city', lookup_expr='icontains')
    gender_type = django_filters.ChoiceFilter(choices=Hostel.GENDER_TYPE_CHOICES)
    is_active = django_filters.BooleanFilter(field_name='is_active')

    class Meta:
        model = Hostel
        fields = ['city', 'gender_type', 'is_active']

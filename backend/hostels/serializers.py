"""
hostels/serializers.py — Hostel serializers with pagination-ready output
"""
from rest_framework import serializers
from .models import Hostel, HostelImage


class HostelImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = HostelImage
        fields = ['id', 'image', 'caption']


class HostelListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views (no heavy fields)."""
    average_rating = serializers.FloatField(read_only=True)
    image_count = serializers.SerializerMethodField()

    class Meta:
        model = Hostel
        fields = [
            'id', 'name', 'city', 'state', 'hostel_type',
            'price_per_month', 'is_available', 'available_rooms',
            'average_rating', 'image_count', 'amenities',
        ]

    def get_image_count(self, obj):
        return obj.images.count()


class HostelDetailSerializer(serializers.ModelSerializer):
    """Full serializer for detail view."""
    images = HostelImageSerializer(many=True, read_only=True)
    average_rating = serializers.FloatField(read_only=True)

    class Meta:
        model = Hostel
        fields = '__all__'

from rest_framework import serializers
from .models import FavoriteHostel, FavoriteRoom


class FavoriteHostelSerializer(serializers.ModelSerializer):
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)
    hostel_city = serializers.CharField(source='hostel.city', read_only=True)
    hostel_price = serializers.DecimalField(
        source='hostel.price_per_month',
        max_digits=8,
        decimal_places=2,
        read_only=True
    )

    class Meta:
        model = FavoriteHostel
        fields = ['id', 'hostel', 'hostel_name', 'hostel_city', 'hostel_price', 'created_at']
        read_only_fields = ['id', 'created_at']


class FavoriteRoomSerializer(serializers.ModelSerializer):
    room_name = serializers.CharField(source='room.room_name', read_only=True)
    hostel_name = serializers.CharField(source='room.hostel.name', read_only=True)
    room_price = serializers.DecimalField(
        source='room.price_per_month',
        max_digits=8,
        decimal_places=2,
        read_only=True
    )

    class Meta:
        model = FavoriteRoom
        fields = ['id', 'room', 'room_name', 'hostel_name', 'room_price', 'created_at']
        read_only_fields = ['id', 'created_at']

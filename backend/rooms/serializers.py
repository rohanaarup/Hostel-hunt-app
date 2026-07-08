from rest_framework import serializers
from .models import Room


class RoomListSerializer(serializers.ModelSerializer):
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)

    class Meta:
        model = Room
        fields = [
            'room_id', 'hostel_name', 'room_name', 'sharing_type',
            'capacity', 'available_beds', 'price_per_month', 'is_active',
        ]


class RoomDetailSerializer(serializers.ModelSerializer):
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)

    class Meta:
        model = Room
        fields = '__all__'
        read_only_fields = ['room_id', 'created_at', 'updated_at', 'hostel']


class RoomCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Room
        fields = [
            'room_id',
            'hostel',
            'room_name',
            'sharing_type',
            'description',
            'capacity',
            'available_beds',
            'price_per_month',
            'has_attached_bathroom',
            'is_ac',
            'is_active',
        ]
        read_only_fields = ['room_id', 'created_at']

    def validate(self, data):
        if data.get('available_beds', 0) > data.get('capacity', 1):
            raise serializers.ValidationError('Available beds cannot exceed room capacity.')
        return data

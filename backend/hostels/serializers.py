from rest_framework import serializers
from .models import Hostel
from media_uploads.models import MediaItem


class MediaItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MediaItem
        fields = ['id', 'file', 'category', 'mime_type', 'file_name', 'order_index']


class HostelListSerializer(serializers.ModelSerializer):
    average_rating = serializers.FloatField(read_only=True)
    image_count = serializers.SerializerMethodField()

    class Meta:
        model = Hostel
        fields = [
            'hostel_id', 'name', 'city', 'state', 'gender_type',
            'is_active', 'average_rating', 'image_count', 'amenities',
        ]

    def get_image_count(self, obj):
        return obj.media_items.count()


class HostelDetailSerializer(serializers.ModelSerializer):
    media_items = MediaItemSerializer(many=True, read_only=True)
    average_rating = serializers.FloatField(read_only=True)

    class Meta:
        model = Hostel
        fields = '__all__'


class HostelCreateSerializer(serializers.ModelSerializer):
    owner_email = serializers.CharField(source='owner.email', read_only=True)

    class Meta:
        model = Hostel
        fields = [
            'hostel_id',
            'owner_email',
            'owner_name',
            'name',
            'description',
            'address',
            'city',
            'state',
            'pincode',
            'landmark',
            'gender_type',
            'total_floors',
            'total_rooms',
            'total_beds',
            'occupancy_types',
            'rules',
            'check_in_policy',
            'check_out_policy',
            'amenities',
            'is_active',
            'latitude',
            'longitude',
            'contact_number',
            'email',
            'created_at',
        ]
        read_only_fields = ['hostel_id', 'owner_email', 'created_at']

    def validate_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError('Hostel name cannot be empty.')
        return value.strip()

    def validate_city(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError('City is required.')
        return value.strip()

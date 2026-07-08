from rest_framework import serializers
from .models import Booking
from hostels.models import Hostel
from rooms.models import Room


class BookingListSerializer(serializers.ModelSerializer):
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)

    class Meta:
        model = Booking
        fields = [
            'booking_id', 'hostel_name', 'room_name',
            'check_in_date', 'check_out_date', 'status',
            'requested_at',
        ]


class BookingDetailSerializer(serializers.ModelSerializer):
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)
    hostel_address = serializers.CharField(source='hostel.address', read_only=True)
    hostel_contact = serializers.CharField(source='hostel.contact_number', read_only=True)

    class Meta:
        model = Booking
        fields = '__all__'
        read_only_fields = [
            'booking_id', 'status', 'requested_at', 'updated_at',
            'user_id', 'user_name', 'user_email', 'user_phone', 'user_profile_photo'
        ]


class BookingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = [
            'booking_id',
            'hostel',
            'room',
            'check_in_date',
            'check_out_date',
            'notes',
        ]

    def validate(self, data):
        hostel = data.get('hostel')
        room = data.get('room')
        
        if room and room.hostel != hostel:
            raise serializers.ValidationError('Room must belong to the selected hostel.')
            
        return data

    def create(self, validated_data):
        user = self.context['request'].user
        
        # Denormalize user data into the booking
        validated_data['user_id'] = str(user.owner_id)
        validated_data['user_name'] = user.display_name
        validated_data['user_email'] = user.email
        validated_data['user_phone'] = user.phone_number or ''
        
        if user.profile_photo:
            validated_data['user_profile_photo'] = user.profile_photo.url
            
        room = validated_data.get('room')
        if room:
            validated_data['room_name'] = room.room_name
            
        return super().create(validated_data)

"""
bookings/serializers.py
"""
from rest_framework import serializers
from .models import Booking


class BookingSerializer(serializers.ModelSerializer):
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'hostel', 'hostel_name', 'user_email',
            'check_in', 'check_out', 'status', 'total_amount',
            'notes', 'created_at',
        ]
        read_only_fields = ['id', 'status', 'user_email', 'created_at']


class CreateBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ['hostel', 'check_in', 'check_out', 'notes']

    def validate(self, attrs):
        if attrs.get('check_out') and attrs['check_out'] <= attrs['check_in']:
            raise serializers.ValidationError({'check_out': 'Check-out must be after check-in.'})
        return attrs

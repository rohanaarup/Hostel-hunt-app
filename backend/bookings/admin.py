from django.contrib import admin
from .models import Booking

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('booking_id', 'user_name', 'hostel', 'room_name', 'status', 'check_in_date')
    list_filter = ('status',)
    search_fields = ('user_name', 'user_email', 'hostel__name')
    ordering = ('-requested_at',)
from django.contrib import admin
from .models import Room

@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = ('room_name', 'hostel', 'sharing_type', 'capacity', 'price_per_month', 'is_active')
    list_filter = ('is_active', 'has_attached_bathroom', 'is_ac')
    search_fields = ('room_name', 'hostel__name')
    ordering = ('hostel', 'room_name')
from django.contrib import admin
from .models import Hostel

@admin.register(Hostel)
class HostelAdmin(admin.ModelAdmin):
    list_display = ('name', 'city', 'owner_name', 'gender_type', 'is_active', 'is_verified')
    list_filter = ('is_active', 'is_verified', 'gender_type', 'city')
    search_fields = ('name', 'city', 'owner_name')
    ordering = ('-created_at',)
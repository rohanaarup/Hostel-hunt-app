from django.contrib import admin
from .models import Review

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('user', 'hostel', 'rating', 'created_at')
    list_filter = ('rating', 'hostel')
    search_fields = ('user__email', 'hostel__name', 'comment')
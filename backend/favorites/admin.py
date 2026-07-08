from django.contrib import admin
from .models import FavoriteHostel, FavoriteRoom


@admin.register(FavoriteHostel)
class FavoriteHostelAdmin(admin.ModelAdmin):
    list_display = ('user', 'hostel', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__email', 'hostel__name')
    readonly_fields = ('created_at',)


@admin.register(FavoriteRoom)
class FavoriteRoomAdmin(admin.ModelAdmin):
    list_display = ('user', 'room', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__email', 'room__room_name')
    readonly_fields = ('created_at',)

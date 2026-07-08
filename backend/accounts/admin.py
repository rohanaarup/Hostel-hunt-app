from django.contrib import admin
from .models import Owner, AppUser, HostelOwner

@admin.register(Owner)
class OwnerAdmin(admin.ModelAdmin):
    list_display = ('email', 'display_name', 'role', 'signup_source', 'is_active', 'is_staff', 'is_verified')
    list_filter = ('role', 'is_active', 'is_staff', 'is_verified')
    ordering = ('-created_at',)

    def save_model(self, request, obj, form, change):
        if not change:
            obj.signup_source = 'admin_panel'
            if obj.password and not obj.password.startswith('pbkdf2_'):
                obj.set_password(obj.password)
        super().save_model(request, obj, form, change)

@admin.register(AppUser)
class AppUserAdmin(admin.ModelAdmin):
    list_display = ('email', 'display_name', 'phone_number', 'signup_source', 'is_active', 'is_verified', 'created_at')
    list_filter = ('is_active', 'is_verified')
    search_fields = ('email', 'display_name', 'phone_number')
    ordering = ('-created_at',)

    def get_queryset(self, request):
        return super().get_queryset(request).filter(role='student')

    def save_model(self, request, obj, form, change):
        if not change:
            obj.signup_source = 'admin_panel'
            obj.role = 'student'
            if obj.password and not obj.password.startswith('pbkdf2_'):
                obj.set_password(obj.password)
        super().save_model(request, obj, form, change)

@admin.register(HostelOwner)
class HostelOwnerAdmin(admin.ModelAdmin):
    list_display = ('email', 'display_name', 'phone_number', 'signup_source', 'is_active', 'is_staff', 'is_verified')
    list_filter = ('is_active', 'is_staff', 'is_verified')
    search_fields = ('email', 'display_name', 'phone_number')
    ordering = ('-created_at',)

    def get_queryset(self, request):
        return super().get_queryset(request).filter(role='owner')

    def save_model(self, request, obj, form, change):
        if not change:
            obj.signup_source = 'admin_panel'
            obj.role = 'owner'
            if obj.password and not obj.password.startswith('pbkdf2_'):
                obj.set_password(obj.password)
        super().save_model(request, obj, form, change)
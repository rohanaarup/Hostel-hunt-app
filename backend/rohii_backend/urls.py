"""
ROHII Backend — Root URL Configuration
All API routes are versioned under /api/
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    # Authentication & Users
    path('api/auth/', include('accounts.urls')),

    # OTP
    path('api/otp/', include('otp_auth.urls')),

    # Hostels
    path('api/hostels/', include('hostels.urls')),

    # Bookings
    path('api/bookings/', include('bookings.urls')),

    # Reviews
    path('api/reviews/', include('reviews.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

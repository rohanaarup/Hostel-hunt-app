import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rohii_backend.settings')
django.setup()

from accounts.serializers import RegisterSerializer
from otp_auth.models import OTPRecord
from accounts.admin import OwnerAdmin
from accounts.models import Owner
from django.contrib.admin.sites import AdminSite

print("Testing App Signup...")
OTPRecord.objects.create(identifier='testapp@example.com', purpose='registration', is_used=True)
serializer = RegisterSerializer(data={
    'display_name': 'Test App User',
    'email': 'testapp@example.com',
    'password': 'ComplexPass123!@#',
    'password_confirm': 'ComplexPass123!@#',
    'signup_source': 'app',
})
serializer.is_valid(raise_exception=True)
user1 = serializer.save()
print("App User signup_source:", user1.signup_source)

print("\nTesting Admin Panel Signup...")
owner = Owner(email='testadmin@example.com', display_name='Test Admin User', password='ComplexPass123!@#')
admin_ui = OwnerAdmin(Owner, AdminSite())
admin_ui.save_model(None, owner, None, False)
print("Admin User signup_source:", owner.signup_source)

print("\nExisting Owners:")
for u in Owner.objects.exclude(email__in=['testapp@example.com', 'testadmin@example.com']):
    print(f"{u.display_name} ({u.email}): {u.signup_source}")


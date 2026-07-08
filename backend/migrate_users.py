import os
import django
import sqlite3
import uuid

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rohii_backend.settings')
django.setup()

from accounts.models import Owner

conn = sqlite3.connect('db.sqlite3')
cursor = conn.cursor()
cursor.execute("SELECT email, password, full_name, is_superuser, is_active, is_staff, email_verified, role, last_login, created_at, updated_at FROM accounts_customuser")
users = cursor.fetchall()

print("Migrating users from local SQLite to Railway Postgres...")
for row in users:
    email = row[0]
    password = row[1]
    display_name = row[2]
    is_superuser = row[3]
    is_active = row[4]
    is_staff = row[5]
    is_verified = row[6]
    role = row[7]
    last_login = row[8]
    created_at = row[9]
    updated_at = row[10]
    
    if not Owner.objects.filter(email=email).exists():
        print(f"Adding user {email}...")
        owner = Owner(
            owner_id=uuid.uuid4(),
            email=email,
            password=password,
            display_name=display_name,
            is_superuser=is_superuser,
            is_active=is_active,
            is_staff=is_staff,
            is_verified=is_verified,
            role=role,
        )
        owner.save()
        # Note: avoiding saving last_login and created_at because of timezone complexities in a quick script, 
        # auto_now_add will handle created_at.
        print(f"Successfully migrated {email}")
    else:
        print(f"User {email} already exists in Postgres. Skipping.")

print("Migration complete!")

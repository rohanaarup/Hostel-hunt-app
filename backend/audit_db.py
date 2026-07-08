#!/usr/bin/env python
"""
Database Audit Script — Inspect PostgreSQL schema and data
"""
import os
import sys
import django
import json

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rohii_backend.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.db import connection
from django.apps import apps
from django.db import models as db_models

print("=" * 80)
print("HOSTEL HUNT — DATABASE AUDIT REPORT")
print("=" * 80)

# 1. Database Connection Info
print("\n[1] DATABASE CONNECTION")
print("-" * 80)
db_config = connection.get_connection_params()
print(f"Host: {db_config.get('host', 'N/A')}")
print(f"Port: {db_config.get('port', 'N/A')}")
print(f"Database: {db_config.get('dbname', 'N/A')}")
print(f"User: {db_config.get('user', 'N/A')}")

# 2. List all tables
print("\n[2] EXISTING TABLES IN DATABASE")
print("-" * 80)
with connection.cursor() as cursor:
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema='public' 
        ORDER BY table_name
    """)
    tables = cursor.fetchall()
    for table in tables:
        print(f"  • {table[0]}")
    print(f"\nTotal Tables: {len(tables)}")

# 3. Data counts per table
print("\n[3] ROW COUNTS PER TABLE")
print("-" * 80)
for table in tables:
    table_name = table[0]
    with connection.cursor() as cursor:
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"  {table_name:<40} {count:>8,} rows")

# 4. Django models
print("\n[4] REGISTERED DJANGO MODELS")
print("-" * 80)
for app_config in apps.get_app_configs():
    app_label = app_config.label
    if app_label not in ['admin', 'auth', 'contenttypes', 'sessions', 'messages', 'staticfiles']:
        print(f"\n  App: {app_label.upper()}")
        for model in app_config.get_models():
            db_table = model._meta.db_table
            print(f"    - {model.__name__} → {db_table}")

# 5. Migration history
print("\n[5] APPLIED MIGRATIONS")
print("-" * 80)
from django.db.migrations.executor import MigrationExecutor
from django.db.migrations.loader import MigrationLoader
loader = MigrationLoader(None, ignore_no_migrations=True)
executor = MigrationExecutor(connection)
graph = loader.graph
targets = executor.loader.graph.leaf_nodes()
print(f"Migration graph targets: {targets}")
for node in sorted(targets):
    print(f"  • {node[0]}.{node[1]}")

# 6. Key tables schema
print("\n[6] KEY TABLE SCHEMAS")
print("-" * 80)
key_tables = ['accounts_customuser', 'hostels_hostel', 'rooms_room', 'bookings_booking', 'reviews_review', 'otp_auth_otprecord']
for table_name in key_tables:
    if any(table[0] == table_name for table in tables):
        print(f"\n  Table: {table_name}")
        with connection.cursor() as cursor:
            cursor.execute(f"""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_name='{table_name}'
                ORDER BY ordinal_position
            """)
            columns = cursor.fetchall()
            for col_name, data_type, nullable in columns:
                nullable_str = "NULL" if nullable == "YES" else "NOT NULL"
                print(f"    {col_name:<35} {data_type:<20} {nullable_str}")

# 7. Users in database
print("\n[7] REGISTERED USERS")
print("-" * 80)
from accounts.models import CustomUser
users = CustomUser.objects.all()
print(f"Total Users: {users.count()}")
for user in users[:10]:  # Show first 10
    print(f"  • {user.full_name} <{user.email}> [Role: {user.role}, Verified: {user.email_verified}]")

# 8. Hostels in database
print("\n[8] HOSTELS IN DATABASE")
print("-" * 80)
from hostels.models import Hostel
hostels = Hostel.objects.all()
print(f"Total Hostels: {hostels.count()}")
for hostel in hostels[:5]:  # Show first 5
    print(f"  • {hostel.name} ({hostel.city}) - {hostel.hostel_type} - ₹{hostel.price_per_month}/month")

# 9. OTP records
print("\n[9] OTP RECORDS")
print("-" * 80)
from otp_auth.models import OTPRecord
otp_records = OTPRecord.objects.all()
print(f"Total OTP Records: {otp_records.count()}")
for record in otp_records[:5]:
    status = "✓ Verified" if record.verified else "✗ Pending"
    print(f"  • {record.email} {status}")

print("\n" + "=" * 80)
print("AUDIT COMPLETE")
print("=" * 80)

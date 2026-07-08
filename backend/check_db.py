import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rohii_backend.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()
cursor.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'owners';")
for row in cursor.fetchall():
    print(row)

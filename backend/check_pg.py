import django, os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rohii_backend.settings')
django.setup()

from django.db import connection
cursor = connection.cursor()

cursor.execute("SELECT tablename FROM pg_tables WHERE schemaname='public'")
tables = [r[0] for r in cursor.fetchall()]
print(f"\n{len(tables)} tables in 'public' schema:")
for t in tables:
    cursor.execute(f"SELECT COUNT(*) FROM public.\"{t}\"")
    count = cursor.fetchone()[0]
    print(f"  {t}: {count} rows")

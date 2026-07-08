#!/usr/bin/env python
"""
READ-ONLY inspection of Railway Postgres — no writes, no schema changes.
Uses the public proxy connection from list_tables.py.
"""
import psycopg2

conn = psycopg2.connect(
    dbname='railway',
    user='postgres',
    password='uaYhWclgLoMaGiArqpPWABDFmeNqEhbp',
    host='thomas.proxy.rlwy.net',
    port=36560
)
conn.set_session(readonly=True)
cur = conn.cursor()

print("=" * 80)
print("RAILWAY POSTGRES — READ-ONLY INSPECTION")
print("=" * 80)

# 1. All tables
print("\n[1] ALL TABLES IN PUBLIC SCHEMA")
print("-" * 80)
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema='public' 
    ORDER BY table_name
""")
tables = [t[0] for t in cur.fetchall()]
for t in tables:
    print(f"  • {t}")
print(f"\nTotal: {len(tables)} tables")

# 2. Row counts
print("\n[2] ROW COUNTS")
print("-" * 80)
for t in tables:
    cur.execute(f'SELECT COUNT(*) FROM "{t}"')
    count = cur.fetchone()[0]
    print(f"  {t:<45} {count:>6} rows")

# 3. django_migrations table (if exists)
if 'django_migrations' in tables:
    print("\n[3] DJANGO_MIGRATIONS HISTORY")
    print("-" * 80)
    cur.execute("SELECT id, app, name, applied FROM django_migrations ORDER BY id")
    rows = cur.fetchall()
    for row in rows:
        print(f"  #{row[0]:>3}  {row[1]:<25} {row[2]}")

# 4. Schema of key tables
print("\n[4] TABLE SCHEMAS")
print("-" * 80)
for t in tables:
    if t.startswith('django_') or t.startswith('auth_'):
        continue
    print(f"\n  === {t} ===")
    cur.execute(f"""
        SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name='{t}'
        ORDER BY ordinal_position
    """)
    cols = cur.fetchall()
    for col_name, dtype, max_len, nullable, default in cols:
        type_str = dtype
        if max_len:
            type_str += f"({max_len})"
        null_str = "NULL" if nullable == "YES" else "NOT NULL"
        print(f"    {col_name:<35} {type_str:<25} {null_str}")

# 5. Check auth_user schema (if the admin panel uses django.contrib.auth.User)
if 'auth_user' in tables:
    print("\n[5] AUTH_USER TABLE SCHEMA")
    print("-" * 80)
    cur.execute("""
        SELECT column_name, data_type, character_maximum_length, is_nullable
        FROM information_schema.columns
        WHERE table_name='auth_user'
        ORDER BY ordinal_position
    """)
    for col_name, dtype, max_len, nullable in cur.fetchall():
        type_str = dtype
        if max_len:
            type_str += f"({max_len})"
        null_str = "NULL" if nullable == "YES" else "NOT NULL"
        print(f"  {col_name:<35} {type_str:<25} {null_str}")

# 6. Sample data from owners-like tables
for candidate in ['owners', 'auth_user', 'accounts_customuser', 'owners_owner']:
    if candidate in tables:
        print(f"\n[6] SAMPLE DATA FROM '{candidate}'")
        print("-" * 80)
        cur.execute(f'SELECT * FROM "{candidate}" LIMIT 5')
        colnames = [desc[0] for desc in cur.description]
        print(f"  Columns: {colnames}")
        rows = cur.fetchall()
        for row in rows:
            # Mask password fields
            row_dict = {}
            for i, col in enumerate(colnames):
                if 'password' in col.lower():
                    row_dict[col] = '***MASKED***'
                else:
                    row_dict[col] = row[i]
            print(f"  Row: {row_dict}")

# 7. Check for hostels data
for candidate in ['hostels', 'hostels_hostel']:
    if candidate in tables:
        print(f"\n[7] SAMPLE DATA FROM '{candidate}'")
        print("-" * 80)
        cur.execute(f'SELECT * FROM "{candidate}" LIMIT 5')
        colnames = [desc[0] for desc in cur.description]
        print(f"  Columns: {colnames}")
        rows = cur.fetchall()
        for row in rows:
            row_dict = dict(zip(colnames, row))
            print(f"  Row: {row_dict}")

cur.close()
conn.close()

print("\n" + "=" * 80)
print("INSPECTION COMPLETE — NO CHANGES MADE")
print("=" * 80)

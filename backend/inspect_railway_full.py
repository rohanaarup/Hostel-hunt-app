#!/usr/bin/env python
"""
Full Railway schema inspection — every table, every column, every constraint.
READ-ONLY.
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

# Get all non-django/auth tables
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema='public' 
    ORDER BY table_name
""")
tables = [t[0] for t in cur.fetchall()]

for t in tables:
    print(f"\n{'='*80}")
    print(f"TABLE: {t}")
    print(f"{'='*80}")
    
    # Columns
    cur.execute(f"""
        SELECT column_name, data_type, character_maximum_length, 
               is_nullable, column_default, numeric_precision, numeric_scale
        FROM information_schema.columns
        WHERE table_name='{t}'
        ORDER BY ordinal_position
    """)
    cols = cur.fetchall()
    for col_name, dtype, max_len, nullable, default, num_prec, num_scale in cols:
        type_str = dtype
        if max_len:
            type_str += f"({max_len})"
        elif num_prec and dtype == 'numeric':
            type_str += f"({num_prec},{num_scale})"
        null_str = "NULL" if nullable == "YES" else "NOT NULL"
        default_str = f" DEFAULT {default}" if default else ""
        print(f"  {col_name:<40} {type_str:<30} {null_str}{default_str}")

    # Primary keys
    cur.execute(f"""
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name='{t}' AND tc.constraint_type='PRIMARY KEY'
    """)
    pks = [r[0] for r in cur.fetchall()]
    if pks:
        print(f"  PK: {pks}")

    # Foreign keys
    cur.execute(f"""
        SELECT kcu.column_name, ccu.table_name AS foreign_table, ccu.column_name AS foreign_column
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_name='{t}' AND tc.constraint_type='FOREIGN KEY'
    """)
    fks = cur.fetchall()
    for col, ftable, fcol in fks:
        print(f"  FK: {col} -> {ftable}.{fcol}")

    # Unique constraints
    cur.execute(f"""
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name='{t}' AND tc.constraint_type='UNIQUE'
    """)
    uniques = [r[0] for r in cur.fetchall()]
    if uniques:
        print(f"  UNIQUE: {uniques}")

    # Indexes
    cur.execute(f"""
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename='{t}'
    """)
    for idx_name, idx_def in cur.fetchall():
        print(f"  IDX: {idx_name}")

# Migration history  
print(f"\n{'='*80}")
print("DJANGO_MIGRATIONS")
print(f"{'='*80}")
cur.execute("SELECT app, name FROM django_migrations ORDER BY id")
for app, name in cur.fetchall():
    print(f"  {app:<25} {name}")

# Content types
print(f"\n{'='*80}")
print("DJANGO_CONTENT_TYPE")
print(f"{'='*80}")
cur.execute("SELECT id, app_label, model FROM django_content_type ORDER BY id")
for ct_id, app_label, model in cur.fetchall():
    print(f"  #{ct_id:<4} {app_label}.{model}")

cur.close()
conn.close()

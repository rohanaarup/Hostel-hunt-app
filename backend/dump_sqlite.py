import sqlite3

conn = sqlite3.connect('db.sqlite3')
cursor = conn.cursor()

# Get tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = cursor.fetchall()
print("Tables in SQLite:")
for t in tables:
    print(t[0])

# Check accounts_customuser or owners table
for table_name in ['accounts_customuser', 'owners']:
    if (table_name,) in tables:
        print(f"\nUsers in {table_name}:")
        cursor.execute(f"SELECT * FROM {table_name}")
        users = cursor.fetchall()
        for u in users:
            print(u)
        
        # Also print column names
        cursor.execute(f"PRAGMA table_info({table_name})")
        columns = cursor.fetchall()
        print(f"Columns: {[c[1] for c in columns]}")

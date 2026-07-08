import psycopg2

conn = psycopg2.connect(
    dbname='railway',
    user='postgres',
    password='uaYhWclgLoMaGiArqpPWABDFmeNqEhbp',
    host='thomas.proxy.rlwy.net',
    port=36560
)
cur = conn.cursor()
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
tables = cur.fetchall()
print("Tables:", [t[0] for t in tables])
conn.commit()
cur.close()
conn.close()

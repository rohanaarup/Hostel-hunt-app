import psycopg2

conn = psycopg2.connect(
    dbname='railway',
    user='postgres',
    password='uaYhWclgLoMaGiArqpPWABDFmeNqEhbp',
    host='thomas.proxy.rlwy.net',
    port=36560
)
cur = conn.cursor()
cur.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")
conn.commit()
cur.close()
conn.close()
print("Dropped and recreated public schema.")

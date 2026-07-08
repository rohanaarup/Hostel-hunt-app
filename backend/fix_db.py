import psycopg2

conn = psycopg2.connect(
    dbname='railway',
    user='postgres',
    password='uaYhWclgLoMaGiArqpPWABDFmeNqEhbp',
    host='thomas.proxy.rlwy.net',
    port=36560
)
cur = conn.cursor()
cur.execute("DELETE FROM django_migrations WHERE app='admin' AND name='0001_initial';")
conn.commit()
cur.close()
conn.close()
print("Fixed migrations.")

import sqlite3

con = sqlite3.connect("history.db")

result = con.execute(
    "SELECT COUNT(*) FROM report_history"
).fetchone()

print(result)

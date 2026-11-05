import os
import subprocess
import sys
from urllib.parse import urlparse

from dotenv import load_dotenv

load_dotenv()

db_url = os.getenv("DATABASE_URL")

filename = sys.argv[1]

parsed = urlparse(db_url)

env = os.environ.copy()

env["PGPASSWORD"] = parsed.password


cmd_drop = [
    "psql",
    "-h",
    parsed.hostname,
    "-p",
    str(parsed.port or 5432),
    "-U",
    parsed.username,
    "-d",
    parsed.path[1:],
    "-c",
    "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO app_db_user;",
]

subprocess.run(cmd_drop, env=env, check=True)


cmd_restore = [
    "psql",
    "-h",
    parsed.hostname,
    "-p",
    str(parsed.port or 5432),
    "-U",
    parsed.username,
    "-d",
    parsed.path[1:],
    "-f",
    filename,
]

subprocess.run(cmd_restore, env=env, check=True)

print(f"Database restored from {filename}")

import os
import subprocess
from datetime import datetime
from urllib.parse import urlparse

from dotenv import load_dotenv

load_dotenv()

db_url = os.getenv("DATABASE_URL")

parsed = urlparse(db_url)

ts = datetime.now().strftime("%Y%m%d_%H%M%S")

filename = f"backups/backup_{ts}.sql"

os.makedirs("backups", exist_ok=True)


env = os.environ.copy()

env["PGPASSWORD"] = parsed.password

cmd = [
    "pg_dump",
    "-h",
    parsed.hostname,
    "-p",
    str(parsed.port or 5432),
    "-U",
    parsed.username,
    "-d",
    parsed.path[1:],
    "-F",
    "p",
    "-f",
    filename,
]

subprocess.run(cmd, env=env, check=True)

print(f"Backup saved to {filename}")

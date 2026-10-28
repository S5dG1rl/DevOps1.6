
#!/bin/bash

set -e

cd /home/appuser/DevOps1.6

git pull origin main

source venv/bin/activate

pip install -r requirements.txt

set -a && source .env && set +a

python -m app.init_db

sudo systemctl restart devops-app

echo "Deployment complete."


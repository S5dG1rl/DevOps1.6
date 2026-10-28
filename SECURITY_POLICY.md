
# Security Policy



## Runtime

- Application runs as appuser. Root execution is forbidden.

- systemd unit: User=appuser, Group=appuser.



## Network (iptables)

- DevOps1 (app): only ports 22 (SSH) and 8000 (HTTP) are open.

- DevOps2 (DB): only port 22 (SSH) and 5432 (PostgreSQL from 192.168.204.10) are open.

- Default INPUT policy: DROP.



## Secrets

- Passwords and keys are stored in .env file (mode 0600, owner appuser).

- .env is in .gitignore and never committed to the repository.

- Only .env.example with placeholders exists in the repository.



## Database

- Dedicated user app_db_user with minimal privileges on mountains_db only.

- Authentication: scram-sha-256, allowed only from the application server IP.


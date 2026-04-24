# EC2 Deployment Checklist

Use this checklist when preparing the first production deployment of the Sage backend on a single EC2 instance.

## 1. Launch the instance

- Create one Linux EC2 instance in the same region as S3 and SQS
- Attach an IAM role to the instance
- Open inbound ports:
  - `22` for SSH
  - `80` for Nginx
  - `443` for Nginx with TLS
  - optional `8000` only for temporary direct testing

## 2. Attach IAM permissions

The EC2 role should be able to:

- send, receive, and delete SQS messages
- read and write objects in:
  - raw uploads bucket
  - audio bucket
  - artifacts bucket

## 3. Install system packages

Install:

- Python 3.12 or your chosen production Python version
- `python3-venv`
- `nginx`
- `git`

Optional:

- `ffmpeg` if you later add audio post-processing

## 4. Copy the project onto the instance

Example target location:

```bash
/opt/sage
```

Expected backend location:

```bash
/opt/sage/backend
```

## 5. Create the backend virtual environment

From `/opt/sage/backend`:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
./scripts/run_migrations.sh
```

## 6. Configure environment variables

Create:

```bash
/opt/sage/backend/.env
```

Minimum production settings:

```env
APP_ENV=production
DEBUG=false
SECRET_KEY=replace-with-a-strong-random-secret
QUEUE_PROVIDER=sqs
SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/sage-document-processing
SQS_REGION=us-east-1
STORAGE_PROVIDER=s3
AWS_REGION=us-east-1
S3_BUCKET_RAW=sage-ai-raw
S3_BUCKET_AUDIO=sage-ai-audio
S3_BUCKET_ARTIFACTS=sage-ai-artifacts
GROQ_API_KEY=replace-with-your-groq-key
DATABASE_URL=postgresql+psycopg://USERNAME:PASSWORD@HOST:5432/DBNAME
```

You can start from:

```bash
cp /opt/sage/backend/.env.production.example /opt/sage/backend/.env
```

## 7. Make the run scripts executable

From `/opt/sage/backend`:

```bash
chmod +x scripts/start_api.sh
chmod +x scripts/start_sqs_worker.sh
chmod +x scripts/install_systemd_services.sh
```

## 8. Smoke test manually

From `/opt/sage/backend`:

```bash
./scripts/start_api.sh
```

In another session:

```bash
./scripts/start_sqs_worker.sh
```

Verify:

- `GET /health`
- `GET /ready`
- upload flow
- SQS message consumption
- S3 upload/audio output

## 9. Add process supervision

Recommended:

- one `systemd` service for the API
- one `systemd` service for the SQS worker

Templates are included here:

- `backend/deploy/systemd/sage-api.service`
- `backend/deploy/systemd/sage-sqs-worker.service`

Copy them into `/etc/systemd/system/` and adjust `User` and `Group` if your EC2 username is not `ubuntu`.

Fastest install path:

```bash
./scripts/install_systemd_services.sh
```

Or run the manual steps below:

Suggested commands:

```bash
sudo cp /opt/sage/backend/deploy/systemd/sage-api.service /etc/systemd/system/
sudo cp /opt/sage/backend/deploy/systemd/sage-sqs-worker.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable sage-api
sudo systemctl enable sage-sqs-worker
sudo systemctl start sage-api
sudo systemctl start sage-sqs-worker
```

Useful checks:

```bash
sudo systemctl status sage-api
sudo systemctl status sage-sqs-worker
journalctl -u sage-api -n 100 --no-pager
journalctl -u sage-sqs-worker -n 100 --no-pager
```

## 10. Put Nginx in front

Configure Nginx to reverse proxy:

- `http://127.0.0.1:8000`

Template included here:

- `backend/deploy/nginx/sage-api.conf`

Typical install flow:

```bash
sudo cp /opt/sage/backend/deploy/nginx/sage-api.conf /etc/nginx/sites-available/sage-api.conf
sudo ln -s /etc/nginx/sites-available/sage-api.conf /etc/nginx/sites-enabled/sage-api.conf
sudo nginx -t
sudo systemctl reload nginx
```

Update `server_name` before enabling the site.

Then point your domain or subdomain at the EC2 instance.

## 10.1 Add HTTPS with Certbot

Once DNS is pointing correctly and Nginx is serving your domain:

```bash
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

After Certbot finishes:

- test HTTPS in the browser
- verify the API still responds through Nginx
- verify `/health` and `/ready` over HTTPS

Useful renewal check:

```bash
sudo certbot renew --dry-run
```

## 11. Final pre-launch checks

- confirm `/ready` returns success
- confirm SQS queue is reachable
- confirm S3 buckets are reachable
- confirm uploads create lectures successfully
- confirm lecture regeneration still works
- confirm daily quota behavior returns `429` after limits are exceeded

## 12. Nice-to-have next

- move secrets into Parameter Store or Secrets Manager
- add CloudWatch log collection
- move from SQLite to PostgreSQL if still temporary
- see [POSTGRESQL_MIGRATION.md](./POSTGRESQL_MIGRATION.md) for the database cutover path

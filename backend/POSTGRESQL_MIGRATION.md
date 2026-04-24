# PostgreSQL Migration Checklist

Use this when moving the Sage backend from SQLite on EC2 to PostgreSQL.

## Why Move

SQLite is acceptable for a very early low-traffic launch, but PostgreSQL is the better long-term choice for:

- concurrent API and worker access
- safer production writes
- easier backup and recovery
- smoother growth beyond one small instance

## 1. Create the database

Choose one of:

- `Amazon RDS PostgreSQL`
- PostgreSQL installed on a VM you manage yourself

Collect:

- host
- port
- database name
- username
- password

## 2. Update the backend environment

Set:

```env
DATABASE_URL=postgresql+psycopg://USERNAME:PASSWORD@HOST:5432/DBNAME
```

## 3. Take a backup of the current SQLite database

Before switching:

```bash
cp /opt/sage/backend/app.db /opt/sage/backend/app.db.backup
```

## 4. Understand the current state

The backend now includes an Alembic migration setup and an initial schema migration.

Important note:

- production environments should use `alembic upgrade head`
- the app still uses SQLAlchemy metadata creation in development mode for convenience
- test the first PostgreSQL boot in a staging environment before switching production

## 5. Recommended migration approach

For the first move, use a fresh PostgreSQL database and verify the application starts cleanly there.

Best path:

1. create a staging PostgreSQL database
2. point a staging `.env` at it
3. verify app startup
4. create test users and test uploads
5. only then switch production

## 6. Data migration options

If you do not need old development data:

- start with a clean PostgreSQL database

If you do need to preserve old data:

- export users, documents, lectures, sections, tracks, and jobs from SQLite
- import them into PostgreSQL with a one-time migration script

Because there is no checked-in migration/import utility yet, treat a data-preserving move as a separate engineering task.

## 7. Validate after switching

After updating `DATABASE_URL`, verify:

- `/health`
- `/ready`
- signup/login
- upload flow
- worker processing
- lecture playback
- delete/regenerate behavior

## 8. Next improvement after PostgreSQL

The next backend hardening step after a PostgreSQL cutover should be:

- keep all future schema changes in reviewed Alembic migrations so production and staging stay in sync

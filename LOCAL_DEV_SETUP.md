## Local Development Setup for `gathering_greenwood_admin`

This repo is the **Rails backend / admin** for the project.  
These steps assume macOS, Linux, or WSL; everyone should be able to follow the **same flow**.

We support two development workflows:

1. **Docker-based development** (recommended for consistency)
2. **Local development** (using `asdf` and local PostgreSQL)

We standardize on:

- **Ruby 3.4.4** and **Node.js 20.0.0**
- **PostgreSQL** as the database
- **Yarn 4 (Plug'n'Play)** for JavaScript dependencies

---

## Quick Start: Docker Development (Recommended)

This approach uses Docker Compose to run both the Rails app and PostgreSQL in containers, ensuring a consistent development environment across all machines.

### Prerequisites

- **Docker Desktop** (or Docker Engine + Docker Compose)
  - macOS: [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
  - Linux: Install `docker` and `docker-compose` via your package manager
  - Windows: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) or WSL2

### Setup Steps

1. **Ensure database configuration exists**:

   If `config/database.yml` doesn't exist, create it from the example:

   ```bash
   cp config/database.example.yml config/database.yml
   ```

   The Docker setup uses environment variables (`DB_HOST=db`), so the default configuration will work.

2. **Start the Docker services**:

   ```bash
   docker compose up -d
   ```

   This will:
   - Build the development Docker image (first time only, takes a few minutes)
   - Start PostgreSQL database container
   - Start the Rails app container (runs entrypoint script automatically)
   - The entrypoint script waits for the database, creates it if needed, runs migrations, and builds JS assets

3. **Verify everything is running**:

   ```bash
   docker compose ps
   ```

   Both `web` and `db` services should show as "Up".

4. **Access the Rails container**:

   ```bash
   docker compose exec web bash
   ```

   You're now inside the container with all dependencies installed. The database has been created and migrated automatically.

### Running the App

**Option A: Run Rails server only**

```bash
docker compose exec web bin/rails server -b 0.0.0.0
```

Visit: `http://localhost:3000`

**Option B: Run with JS watcher (recommended for active development)**

In one terminal, start the Rails server:

```bash
docker compose exec web bin/rails server -b 0.0.0.0
```

In another terminal, start the JS watcher:

```bash
docker compose exec web yarn build --watch
```

**Option C: Run both with foreman (inside container)**

```bash
docker compose exec web bin/dev
```

### Common Docker Commands

- **View logs**:
  ```bash
  docker compose logs -f web    # Rails app logs
  docker compose logs -f db     # Database logs
  ```

- **Run Rails console**:
  ```bash
  docker compose exec web bin/rails console
  ```

- **Run tests**:
  ```bash
  docker compose exec web bundle exec rspec
  ```

- **Rebuild JavaScript assets**:
  ```bash
  docker compose exec web yarn build
  ```

- **Run database migrations**:
  ```bash
  docker compose exec web bin/rails db:migrate
  ```

- **Stop services**:
  ```bash
  docker compose down
  ```

- **Stop and remove volumes** (clean slate):
  ```bash
  docker compose down -v
  ```

- **Rebuild the Docker image** (after Dockerfile changes):
  ```bash
  docker compose build --no-cache
  ```

### Docker Development Notes

- **Code changes**: Your local code is mounted as a volume, so changes are immediately reflected in the container (no rebuild needed).
- **Dependencies**: Ruby gems and Node modules are cached in Docker volumes for faster rebuilds.
- **Database**: PostgreSQL data persists in a Docker volume (`postgres-data`).
- **Ports**: 
  - Rails app: `http://localhost:3000`
  - PostgreSQL: `localhost:5433` (mapped from container port 5432, if you need direct DB access)

### Troubleshooting Docker Setup

- **Container won't start**: 
  - Check logs with `docker compose logs web`
  - If you see migration errors, the container will still start but migrations may need manual fixing
  - Rebuild the container after changing `docker-entrypoint.sh`: `docker compose build web`
- **Database connection errors**: Ensure the `db` service is healthy: `docker compose ps`
- **Migration errors**: 
  - The entrypoint script will warn but not fail if migrations have issues
  - You can run migrations manually: `docker compose exec web bundle exec rails db:migrate`
  - If migrations fail due to missing tables, you may need to run them in a specific order or fix the migration files
- **Permission errors**: On Linux, you may need to fix file permissions:
  ```bash
  sudo chown -R $USER:$USER .
  ```
- **Port already in use**: 
  - If port 5432 is in use (local PostgreSQL), the Docker setup uses port 5433 instead
  - If port 3000 is in use, change it in `docker-compose.yml`: `"127.0.0.1:3001:3000"`
- **Need to reset everything**: `docker compose down -v && docker compose up -d`

---

## Local Development Setup (Without Docker)

If you prefer to run everything locally without Docker, follow these steps:

### 1. Prerequisites

- Git
- PostgreSQL (local install or via Docker)
- [`asdf`](https://asdf-vm.com/guide/getting-started.html) installed and initialized in your shell
  - After installation, in a new terminal, `asdf --version` should work.
- Node/Yarn (managed by `asdf` and Corepack as described below)

---

### 2. Set up languages with `asdf`

This repo includes `.tool-versions`:

```text
ruby 3.4.4
nodejs 20.0.0
```

Install the plugins (once per machine):

```bash
asdf plugin add ruby   || true
asdf plugin add nodejs || true
```

Install the versions for this project:

```bash
asdf install       # reads .tool-versions
asdf current       # should show ruby 3.4.4 and nodejs 20.0.0
```

Confirm Ruby:

```bash
ruby -v           # should report 3.4.4
```

If Ruby still reports a different version, ensure `asdf` is initialized in your shell
per the asdf docs, then open a new terminal and run the above again.

---

### 3. Database configuration

Create a development database config based on the example:

```bash
cp config/database.example.yml config/database.yml
```

- If you use **local PostgreSQL**, edit `config/database.yml` and set:

  ```yaml
  host: localhost
  ```

- If you use **Docker / devcontainer Postgres**, keep `host: db` and ensure the
  container network matches.

Create and migrate the database:

```bash
bin/rails db:create db:migrate
```

---

### 4. Install Ruby gems

From the repo root:

```bash
bundle install
```

If you switch Ruby versions in the future, you may want to refresh:

```bash
bundle install
```

---

### 5. Install JavaScript dependencies (Yarn 4, Plug'n'Play)

This repo uses Yarn 4 with Plug'n'Play. The `package.json` declares:

```json
"packageManager": "yarn@4.x.x"
```

Enable Corepack and install dependencies:

```bash
corepack enable
yarn install
```

This will create/update:

- `.pnp.cjs`
- `.pnp.loader.mjs`
- `.yarn/` (PnP cache)
- `yarn.lock`

---

### 6. Build JavaScript assets (one-time or as needed)

To build the JS bundles into `app/assets/builds`:

```bash
yarn build
```

This compiles:

- `app/javascript/application.js`
- `app/javascript/cms.js`
- `app/javascript/document.js`

into `app/assets/builds`, which Rails serves via the asset pipeline.

---

### 7. Running the app

### Option A: Rails only (simplest)

```bash
bin/rails server
```

Visit:

- `http://localhost:3000`

The JS assets will come from the last `yarn build`.  
Use this when you just need the backend running and don’t need live JS rebuilds.

### Option B: Using `bin/dev` (Rails + JS watcher)

`bin/dev` runs both the Rails server and a JS build watcher via `foreman`:

```bash
bin/dev
```

This uses `Procfile.dev` to start:

- `web`: `bin/rails server -p 3000`
- `js`: `yarn build --watch`

Use this when actively working on JavaScript; changes will trigger rebuilds.

If `foreman` is missing, `bin/dev` will install it automatically with the
currently active Ruby (via `asdf`).

---

### 8. Common tasks

- **Run Rails console**

  ```bash
  bin/rails console
  ```

- **Run tests**

  ```bash
  bundle exec rspec
  ```

- **Rebuild JS assets**

  ```bash
  yarn build
  ```

---

### 9. Troubleshooting

- **Ruby version mismatch**
  - Ensure `asdf` is initialized in your shell.
  - Run `asdf install` and verify with `asdf current` and `ruby -v`.

- **Database connection errors**
  - Check `config/database.yml` (`host`, `username`, `password`).
  - Ensure PostgreSQL is running.

- **Missing JS assets (`application.js` not present in asset pipeline)**
  - Run `yarn install` and `yarn build`.
  - Then restart `bin/rails server` or `bin/dev`.



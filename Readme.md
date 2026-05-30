<div align="center">

<img src="https://img.shields.io/badge/Drop4Life-Blood%20Donation%20System-red?style=for-the-badge&logo=heart&logoColor=white" alt="Drop4Life"/>

# 🩸 Drop4Life

### A production-ready Blood Donation System connecting donors with those in need

[![FastAPI](https://img.shields.io/badge/FastAPI-0.135.1-009688?style=flat-square&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Latest-336791?style=flat-square&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-7.x-DC382D?style=flat-square&logo=redis&logoColor=white)](https://redis.io)
[![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

[Features](#-features) · [Tech Stack](#-tech-stack) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [API Docs](#-api-documentation) · [Deployment](#-deployment) · [Project Journey](#-project-journey)

</div>

---

## 📖 Overview

**Drop4Life** is a full-stack, production-grade blood donation platform built to bridge the gap between blood donors and hospitals in emergency situations. It provides real-time matching, live donor tracking, and instant notifications — all through a unified backend API consumed by both a web frontend and a Flutter mobile app.

This project was built progressively — from a bare FastAPI server to a fully deployed system — making it both a working product and a complete learning reference for modern backend engineering.

---

##  Features

### Core
-  **Firebase Authentication** with JWT verification and role-based access control (RBAC)
-  **Blood Request Management** — hospitals post urgent requests, donors respond in real time
-  **Blood Compatibility Engine** — automatic donor-request matching by blood type
-  **Live Donor Location Tracking** — proximity-based filtering using lat/lng coordinates
-  **Donor Cooldown System** — enforces 90-day cooldown after donation using background tasks
-  **Real-Time Notifications** — WebSocket-powered event system (FCM + Redis Pub/Sub)

### Platform
-  **Web Frontend** — fully integrated, no mock data
-  **Flutter Mobile App** — iOS/Android, connected to the same backend APIs
-  **Async External API Integration** — with retry logic and error handling
-  **Rate Limiting** — per-route request throttling via SlowAPI
-  **Redis Caching** — response caching for high-traffic endpoints
-  **Pagination & Filtering** — on all list endpoints
-  **Docker & Docker Compose** — one-command local setup
-  **CI/CD via GitHub Actions** — auto-deploy on push to main

---

## 🛠 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Backend** | FastAPI (Python 3.14) | REST API, WebSockets, Background Tasks |
| **ORM** | SQLAlchemy 2.0 | Database modeling & queries |
| **Migrations** | Alembic | Schema version control |
| **Database** | PostgreSQL | Primary relational data store |
| **Cache** | Redis 7.x | Caching, Rate limiting|
| **Auth** | Firebase Auth + JWT | Identity & token verification |
| **Auth Middleware** | firebase-admin, PyJWT | Token decoding & Firebase SDK |
| **Async HTTP** | httpx | External API calls with retry logic |
| **Task Scheduling** | APScheduler | Donor cooldown jobs |
| **Rate Limiting** | SlowAPI | Per-route request throttling |
| **Server** | Uvicorn + uvloop | ASGI server, high-performance event loop |
| **Config** | pydantic-settings | Typed env var management |
| **Frontend** | HTML / CSS / JavaScript | Web UI |
| **Real-Time (Web)** | Native WebSocket API | Live donor & request updates |
| **Mobile** | Flutter (Dart) | Cross-platform iOS & Android app |
| **Mobile Auth** | firebase_auth (Flutter) | Firebase login on device |
| **Mobile HTTP** | dio / http (Flutter) | API calls from mobile |
| **Containerization** | Docker | Portable app packaging |
| **Orchestration** | Docker Compose | Multi-service local environment |
| **Hosting** | Render | Cloud deployment |
| **CI/CD** | GitHub Actions | Automated deployment pipeline |
| **Version Control** | Git + GitHub | Source control |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                 │
│                                                                 │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐ │
│   │  Web Browser │    │  Flutter App │    │  Admin Dashboard │ │
│   │  (HTML/JS)   │    │ (iOS/Android)│    │  (WebSocket)     │ │
│   └──────┬───────┘    └──────┬───────┘    └────────┬─────────┘ │
└──────────┼────────────────────┼───────────────────┼────────────┘
           │  REST / WebSocket  │                   │
           ▼                    ▼                   ▼
┌──────────────────────────────────────────────────────────────────┐
│                      FastAPI Backend                             │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐  ┌─────────┐ │
│  │   /donors  │  │ /requests  │  │  /hospitals  │  │  /users │ │
│  └────────────┘  └────────────┘  └──────────────┘  └─────────┘ │
│                                                                  │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────────────┐   │
│  │  Firebase    │  │  Rate       │  │  WebSocket Manager   │   │
│  │  Auth / JWT  │  │  Limiter    │  │  (Redis Pub/Sub)     │   │
│  └──────────────┘  └─────────────┘  └──────────────────────┘   │
│                                                                  │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────────────┐   │
│  │  Background  │  │  Geocoding  │  │  FCM Notifications   │   │
│  │  Tasks /     │  │  Service    │  │  Service             │   │
│  │  APScheduler │  └─────────────┘  └──────────────────────┘   │
│  └──────────────┘                                               │
└──────────────────────────┬───────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌─────────────┐  ┌─────────────┐  ┌──────────────┐
   │ PostgreSQL  │  │    Redis    │  │   Firebase   │
   │  (Primary   │  │  (Cache +   │  │  (Auth +     │
   │   Store)    │  │   PubSub)   │  │   FCM Push)  │
   └─────────────┘  └─────────────┘  └──────────────┘
```

### Project Structure

```
drop4life/
│
├── backend/
│   ├── main.py                    # App entry point, middleware, WebSocket
│   ├── database.py                # SQLAlchemy engine & session
│   ├── firebase.py                # Firebase Admin SDK init
│   ├── config.py                  # Legacy (see core/config.py)
│   │
│   ├── core/
│   │   ├── config.py              # ✅ Pydantic settings — single source of truth
│   │   ├── cache.py               # Redis cache helpers
│   │   ├── pagination.py          # Reusable pagination logic
│   │   ├── rate_limiter.py        # SlowAPI limiter instance
│   │   ├── scheduler.py           # APScheduler for cooldown jobs
│   │   └── websocket_manager.py   # Room-based WebSocket manager
│   │
│   ├── models/
│   │   ├── user.py                # User SQLAlchemy model
│   │   ├── donor.py               # Donor model (incl. cooldown, location)
│   │   ├── hospitals.py           # Hospital model (incl. location)
│   │   └── blood_requests.py      # BloodRequest model
│   │
│   ├── schemas/
│   │   ├── user.py                # Pydantic request/response schemas
│   │   ├── donor.py
│   │   ├── hospital.py
│   │   ├── blood_request.py
│   │   └── common.py              # Shared schemas (pagination, etc.)
│   │
│   ├── routers/
│   │   ├── users.py               # User registration, profile
│   │   ├── donors.py              # Donor CRUD, location, availability
│   │   ├── hospitals.py           # Hospital CRUD
│   │   └── blood_requests.py      # Request lifecycle, fulfillment
│   │
│   ├── dependencies/
│   │   └── auth.py                # Firebase JWT verification dependency
│   │
│   ├── services/
│   │   ├── fcm_service.py         # Firebase Cloud Messaging
│   │   ├── geocoding_service.py   # Location / proximity service
│   │   └── notification_services.py # Event-driven notification dispatcher
│   │
│   └── utils/
│       └── blood_compatibility.py # Blood type matching logic
│
├── alembic/
│   ├── env.py
│   └── versions/                  # Migration history
│       ├── 31e51e640172_initial_clean_schema.py
│       ├── 94f12806ee75_add_cooldown_fields_to_donor.py
│       ├── 20ac9e3cf35b_add_location_to_donor.py
│       ├── 8ab52cb6ab59_add_location_to_hospital.py
│       └── 7139c3433c61_add_fcm_token_to_users.py
│
├── Web-Frontend/                  # HTML/CSS/JS web client
│
├── mobile_app/                    # Flutter mobile application
│
├── .env.example                   #  Safe to commit — no real secrets
├── .env                           #  Never commit — gitignored
├── .gitignore
├── Dockerfile                     # Backend container definition
├── docker-compose.yml             # Multi-service local setup
├── requirements.txt
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- PostgreSQL 14+
- Redis 7+
- Docker & Docker Compose (optional but recommended)
- Firebase project with a service account key
- Flutter SDK (for mobile app)

---

### Option A — Docker Compose (Recommended)

The fastest way to run the full stack locally. One command starts the backend, PostgreSQL, and Redis together.

```bash
# 1. Clone the repository
git clone https://github.com/adityarajput0704/drop4life.git
cd drop4life

# 2. Copy the environment template
cp .env.example .env

# 3. Fill in your values in .env
#    (DATABASE_URL, FIREBASE credentials, etc.)
nano .env

# 4. Start all services
docker compose up --build

# Backend will be live at: http://localhost:8000
# API docs at:             http://localhost:8000/docs
```

---

### Option B — Manual Local Setup

```bash
# 1. Clone the repository
git clone https://github.com/adityarajput0704/drop4life.git
cd drop4life

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment variables
cp .env.example .env
# Edit .env with your actual credentials

# 5. Run database migrations
alembic upgrade head

# 6. Start the development server
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

---

### Environment Variables

Copy `.env.example` to `.env` and fill in the values:

```bash
# App
APP_NAME=Drop4Life
ENVIRONMENT=development
DEBUG=True

# Database (PostgreSQL)
DATABASE_URL=postgresql://user:password@localhost:5432/drop4life

# Redis
REDIS_URL=redis://localhost:6379

# Firebase
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
FIREBASE_SERVICE_ACCOUNT_JSON=          # Used in production (Render dashboard)

# CORS — comma-separated frontend origins
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5500
```

>  **Never commit `.env` or your Firebase service account JSON to Git.** Both are listed in `.gitignore`.

---

### Running Migrations

```bash
# Apply all migrations (run after any schema change)
alembic upgrade head

# Create a new migration after changing a model
alembic revision --autogenerate -m "describe your change"

# Check current migration state
alembic current
```

---

##  API Documentation

FastAPI generates interactive docs automatically. Once the server is running:

| Interface | URL |
|---|---|
| Swagger UI (interactive) | `http://localhost:8000/docs` |
| ReDoc (clean reference) | `http://localhost:8000/redoc` |
| OpenAPI JSON schema | `http://localhost:8000/openapi.json` |

### Key Endpoints

#### Authentication
All protected routes require a Firebase ID token in the `Authorization` header:
```
Authorization: Bearer <firebase_id_token>
```

#### Donors
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/donors/register` | Register as a donor |
| `GET` | `/donors/` | List all available donors (paginated, filterable) |
| `GET` | `/donors/nearby` | Find donors by proximity (lat/lng + radius) |
| `PUT` | `/donors/location` | Update donor's live location |
| `PUT` | `/donors/availability` | Toggle donor availability |
| `GET` | `/donors/{id}` | Get donor profile |

#### Blood Requests
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/blood-requests/` | Create a new blood request (hospitals) |
| `GET` | `/blood-requests/` | List all open requests (paginated) |
| `GET` | `/blood-requests/{id}` | Get request details |
| `PUT` | `/blood-requests/{id}/accept` | Accept a request (donors) |
| `PUT` | `/blood-requests/{id}/fulfill` | Mark request as fulfilled |

#### Hospitals
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/hospitals/register` | Register a hospital |
| `GET` | `/hospitals/` | List all hospitals |
| `GET` | `/hospitals/{id}` | Get hospital details |
| `PUT` | `/hospitals/{id}/location` | Update hospital location |

#### Users
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/users/register` | Register a new user |
| `GET` | `/users/me` | Get current user profile |
| `PUT` | `/users/me/fcm-token` | Update push notification token |

#### WebSocket
```
ws://localhost:8000/ws/{room}

Rooms:
  /ws/admin           → Admin dashboard (all events)
  /ws/hospital_{id}   → Hospital-specific notifications
  /ws/donor_{id}      → Donor-specific notifications
```

### Filtering & Pagination

All list endpoints support query parameters:

```
GET /donors/?blood_type=A+&city=Mumbai&available=true&page=1&limit=20
GET /blood-requests/?blood_type=O-&status=open&page=1&limit=10
```

---

## 🐳 Docker

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose

```yaml
version: "3.9"

services:
  api:
    build: .
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: drop4life
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  pgdata:
```

---

## ☁️ Deployment

This project is deployed on **Render** with managed PostgreSQL and Redis add-ons.

### Deploy to Render

1. Push your code to GitHub
2. Go to [render.com](https://render.com) → New → Web Service
3. Connect your GitHub repository
4. Set the following:
   - **Environment:** Python 3
   - **Build command:** `pip install -r requirements.txt && alembic upgrade head`
   - **Start command:** `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
5. Add all environment variables from `.env.example` in the Render dashboard
6. For `FIREBASE_SERVICE_ACCOUNT_JSON` — paste the full JSON content of your service account key as a single-line string

### Environment Differences

| Variable | Local (`.env`) | Production (Render dashboard) |
|---|---|---|
| `ENVIRONMENT` | `development` | `production` |
| `DEBUG` | `True` | `False` |
| `DATABASE_URL` | `postgresql://localhost/...` | Render PostgreSQL URL |
| `REDIS_URL` | `redis://localhost:6379` | Render Redis URL |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `./firebase-service-account.json` | *(leave blank)* |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | | Full JSON string |

### CI/CD with GitHub Actions

The repository includes a GitHub Actions workflow that automatically deploys to Render on every push to `main`.

```yaml
# .github/workflows/deploy.yml
name: Deploy to Render

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Trigger Render Deploy
        run: |
          curl -X POST ${{ secrets.RENDER_DEPLOY_HOOK_URL }}
```

Set `RENDER_DEPLOY_HOOK_URL` in your GitHub repository secrets (Settings → Secrets → Actions).

---

## 📱 Flutter Mobile App

The Flutter app is located in the `mobile_app/` directory.

### Setup

```bash
cd mobile_app

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Configuration

Update the base URL in `lib/services/api_service.dart`:

```dart
// Development
const String baseUrl = 'http://10.0.2.2:8000';  // Android emulator
// const String baseUrl = 'http://localhost:8000';  // iOS simulator

// Production
// const String baseUrl = 'https://your-app.onrender.com';
```

The app uses Firebase Auth on device. Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed correctly and added to `.gitignore`.

---

## 🔔 Real-Time System

The notification system is event-driven and works across three layers:

```
Event occurs (e.g. blood request created)
         │
         ▼
   FastAPI handler
         │
         ├──► Redis Pub/Sub publish to channel
         │
         ├──► WebSocket broadcast to connected clients
         │         (hospital dashboards, admin)
         │
         └──► FCM push notification
                   (Flutter app, offline devices)
```

### WebSocket Events

```json
{ "event": "request_created",  "data": { "request_id": 1, "blood_type": "O-", "hospital": "City Hospital" } }
{ "event": "request_accepted", "data": { "request_id": 1, "donor_id": 42 } }
{ "event": "request_fulfilled", "data": { "request_id": 1 } }
{ "event": "donor_location_updated", "data": { "donor_id": 42, "lat": 19.076, "lng": 72.877 } }
```

---

## 🧬 Blood Compatibility

The system implements standard blood type compatibility rules:

| Donor Type | Can Donate To |
|---|---|
| O− | O−, O+, A−, A+, B−, B+, AB−, AB+ |
| O+ | O+, A+, B+, AB+ |
| A− | A−, A+, AB−, AB+ |
| A+ | A+, AB+ |
| B− | B−, B+, AB−, AB+ |
| B+ | B+, AB+ |
| AB− | AB−, AB+ |
| AB+ | AB+ only |

Compatibility is checked automatically when matching donors to blood requests.

---

## ⏱️ Donor Cooldown System

After a donation is recorded, the system automatically:

1. Sets `last_donated_at` timestamp on the donor record
2. Sets `is_available = False`
3. Schedules a background job via APScheduler to re-enable the donor after **90 days**
4. Blocks any manual override of availability during the cooldown period

```python
# Cooldown enforced in donor update route
if donor.last_donated_at:
    days_since = (datetime.utcnow() - donor.last_donated_at).days
    if days_since < 90:
        raise HTTPException(
            status_code=400,
            detail=f"Donor is in cooldown. {90 - days_since} days remaining."
        )
```

---

## 🗺️ Live Location Tracking

Donors can update their real-time location via the API. The proximity search uses the **Haversine formula** to find donors within a given radius:

```
GET /donors/nearby?lat=19.076&lng=72.877&radius_km=10&blood_type=O-
```

Returns donors sorted by distance, closest first.

---

## 🧪 Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=backend --cov-report=html

# Test a specific module
pytest tests/test_donors.py -v
```

> Tests use a separate test database. Set `TEST_DATABASE_URL` in your `.env` or pass it directly:
> ```bash
> TEST_DATABASE_URL=postgresql://localhost/drop4life_test pytest
> ```

---

# Contributing to Drop4Life

Drop4Life is a real-time blood donation platform built with FastAPI, PostgreSQL, Redis, Flutter, and React.

This document lists every known technical gap in the system — prioritised by severity. If you want to contribute meaningfully to a production health-tech project, start here.

---

## How to Contribute

1. Fork the repository
2. Pick an open gap below
3. Open an issue referencing the gap (use the gap title as the issue title)
4. Get confirmation before starting work on large changes
5. Submit a PR with tests and a clear description of what changed and why

---

## Critical Gaps — Blocks Production Scale

These directly affect the core promise of the system: matching a donor within 2 seconds during a blood emergency.

---

### 1. No spatial indexing on donor location columns

**File:** `backend/models/donor.py`, `alembic/versions/`

**Problem:**
Donor matching currently fetches all donors from PostgreSQL, then filters by distance in Python using the Haversine formula. At 10,000+ donors this will take 5–10 seconds — well past the 2-second target.

**What's needed:**
- Add PostGIS extension to PostgreSQL
- Add `GEOGRAPHY` or `GEOMETRY` column type to the donors table
- Create a spatial index (`GIST`) on that column
- Rewrite the donor search query to use `ST_DWithin` — filtering happens inside the DB, not Python
- Create an Alembic migration for the schema change

**Skills needed:** PostgreSQL, PostGIS, SQLAlchemy, Alembic

**Reference:** [PostGIS ST_DWithin docs](https://postgis.net/docs/ST_DWithin.html)

---

### 2. Single Uvicorn worker — no horizontal scaling

**File:** `Dockerfile`, `render.yaml` (to be created)

**Problem:**
The app runs with `--workers 1`. A single CPU-intensive request (like a large donor search) blocks all other requests. One crash takes the entire system down.

**What's needed:**
- Configure Uvicorn to use multiple workers via `WEB_CONCURRENCY` env var
- Ensure WebSocket state (currently in-memory via `ConnectionManager`) is moved to Redis so all workers share the same connection state
- Update `backend/core/websocket_manager.py` to use Redis Pub/Sub as the shared state layer instead of a local dict

**Skills needed:** FastAPI, Redis Pub/Sub, WebSockets, Docker

**Note:** The Redis Pub/Sub scaffolding already exists in the codebase — it needs to be completed and wired to the WebSocket manager.

---

### 3. Cold start latency on free hosting tier

**File:** `backend/routers/` (new health endpoint), deployment config

**Problem:**
Render free tier spins down after 15 minutes of inactivity. Cold starts take 20–30 seconds. In a blood emergency, this is unacceptable.

**What's needed:**
- Add a `/health` endpoint that returns system status (DB connectivity, Redis connectivity, uptime)
- Document UptimeRobot or similar keep-alive configuration
- Add a `render.yaml` file for infrastructure-as-code deployment config
- Optionally: add a `/health/ready` and `/health/live` endpoint following Kubernetes liveness/readiness probe conventions

**Expected response from `/health`:**
```json
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected",
  "uptime_seconds": 3600,
  "version": "1.0.0"
}
```

**Skills needed:** FastAPI, PostgreSQL, Redis, deployment config

---

### 4. No database connection pooling configuration

**File:** `backend/database.py`

**Problem:**
SQLAlchemy is using default pool settings. Under concurrent load, the app will exhaust PostgreSQL connections and throw `OperationalError: connection pool exhausted`.

**What's needed:**
- Configure `pool_size`, `max_overflow`, `pool_recycle`, and `pool_pre_ping` on the SQLAlchemy engine
- Enable Neon's connection pooler (PgBouncer) by switching to the pooled connection string
- Add a connection pool health check to the `/health` endpoint

**Recommended settings for a small production deployment:**
```python
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_recycle=300,
    pool_pre_ping=True,
)
```

**Skills needed:** SQLAlchemy, PostgreSQL, connection pooling concepts

---

##  Hardening Gaps — Needed Before Real Users

---

### 5. PII exposed in raw error responses

**File:** `backend/main.py` (global exception handler)

**Problem:**
Unhandled exceptions return raw Python tracebacks or SQLAlchemy error messages to the client. These can expose blood type, location coordinates, Firebase UIDs, and database schema details.

**What's needed:**
- Add a global exception handler in `main.py` that catches all unhandled exceptions
- Return a sanitised `500` response with a generic message and a unique error ID
- Log the full error server-side (with the error ID) so it can be debugged without exposing it to the client

**Example:**
```python
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    error_id = str(uuid.uuid4())[:8]
    logger.error(f"[UNHANDLED ERROR] id={error_id} path={request.url.path} error={exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal error occurred.", "error_id": error_id}
    )
```

**Skills needed:** FastAPI, Python exception handling, logging

---

### 6. No audit trail for sensitive data access

**File:** `backend/models/` (new `AuditLog` model), `backend/dependencies/auth.py`

**Problem:**
There is no record of who accessed which donor's data, when, and from which IP. This is a basic requirement for healthcare data compliance (DISHA in India, HIPAA internationally).

**What's needed:**
- Create an `AuditLog` model with fields: `user_id`, `action`, `resource_type`, `resource_id`, `ip_address`, `timestamp`
- Create a FastAPI dependency `log_access(resource_type, resource_id)` that writes to this table
- Apply it to sensitive routes: `GET /donors/{id}`, `GET /users/me`, `PATCH /blood-requests/{id}/accept`
- Create an Alembic migration

**Skills needed:** SQLAlchemy, FastAPI dependencies, Alembic

---

### 7. No user data deletion endpoint (Right to be Forgotten)

**File:** `backend/routers/users.py`

**Problem:**
Users cannot delete their own accounts. Under GDPR and India's DPDP Act, users have the right to request deletion of their personal data.

**What's needed:**
- Add `DELETE /users/me` endpoint
- Soft delete or hard delete the user record
- Anonymise associated blood request records (replace donor name with "Anonymous Donor")
- Revoke the Firebase account via Firebase Admin SDK
- Return `204 No Content` on success

**Skills needed:** FastAPI, SQLAlchemy, Firebase Admin SDK

---

### 8. No data retention policy

**File:** `backend/core/scheduler.py`

**Problem:**
Donor location updates, old fulfilled blood requests, and system logs are kept indefinitely. This is a compliance risk and a storage cost.

**What's needed:**
- Add a scheduled job (APScheduler already exists in the project) that runs weekly
- Purge donor location history older than 30 days
- Archive fulfilled/cancelled blood requests older than 1 year
- Add configuration variables: `LOCATION_RETENTION_DAYS`, `REQUEST_ARCHIVE_DAYS`

**Skills needed:** APScheduler, SQLAlchemy, data lifecycle management

---

### 9. asyncio.run() inside sync background tasks

**File:** `backend/services/notification_services.py`

**Problem:**
`asyncio.run()` creates a new event loop. Inside FastAPI's async context, calling it from a sync function that runs inside the existing event loop causes `RuntimeError: This event loop is already running` — intermittently in production.

**What's needed:**
- Replace all `asyncio.run(_broadcast(...))` calls with proper async handling
- Convert notification functions to `async def` 
- Use `asyncio.create_task()` or `BackgroundTasks` correctly
- Add error handling that does not swallow failures silently

**Skills needed:** Python asyncio, FastAPI background tasks

---

##  Feature Gaps — Good First Issues

These are lower risk and good starting points for new contributors.

---

### 10. API versioning

**File:** `backend/main.py`, all routers

**Problem:**
All routes are at `/donors`, `/blood-requests` etc. with no version prefix. Adding breaking changes in future requires coordinating all clients simultaneously.

**What's needed:**
- Prefix all routes with `/api/v1/`
- Add redirect from legacy unversioned routes for backwards compatibility
- Update Flutter and web frontend base URLs

---

### 11. Pytest test suite

**File:** `tests/` (new directory)

**Problem:**
There are zero automated tests. Every deploy is a manual verification exercise.

**What's needed:**
- Set up `pytest` with `httpx.AsyncClient` for async route testing
- Write tests for: user registration, donor creation, blood request lifecycle (create → accept → fulfil)
- Add a GitHub Actions step that runs tests on every PR
- Minimum 60% coverage on routers

---

### 12. Flutter offline support

**File:** `App/lib/providers/`

**Problem:**
When the device has no internet, the app shows a blank screen or spinner indefinitely. In a rural emergency, connectivity is unreliable.

**What's needed:**
- Cache the last successful donor list and blood request list using `shared_preferences`
- Show cached data with a "Last updated X minutes ago" banner when offline
- Retry API calls automatically when connectivity is restored using `connectivity_plus` package

---

## Development Setup

```bash
# Clone
git clone https://github.com/adityarajput0704/Drop4Life
cd Drop4Life

# Backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # fill in your values

# Run with Docker (recommended)
docker compose up --build

# Flutter
cd App
flutter pub get
flutter run
```

---

## Code Standards

- Backend: follow existing router/schema/model/service separation
- All new endpoints must have Pydantic request and response schemas
- All new database columns must have an Alembic migration
- No hardcoded secrets — everything goes through `backend/config.py`
- PRs without a description of the gap being fixed will not be reviewed

---

## Questions

Open a GitHub Discussion or reach out via the issue tracker. All contributions are welcome — from fixing a typo in docs to implementing PostGIS spatial indexing.

## 🔒 Security Notes

- All secrets are managed via environment variables — never committed to Git
- Firebase ID tokens are verified on every protected request
- Rate limiting is enforced globally and per-route
- CORS origins are restricted in production (not `*`)
- Database connections use `pool_pre_ping=True` to handle dropped connections
- The Firebase service account JSON is passed as an env var string in production (no file system dependency)

---

## 👤 Author

**Aditya Rajput**

Built as a structured full-stack engineering journey — from FastAPI fundamentals to production deployment — with a focus on real-world architecture, clean code, and production-grade practices.

[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat-square&logo=github)](https://github.com/adityarajput0704)

---

<div align="center">

Made with ❤️ 

**If this project helped you, please give it a ⭐**

</div>

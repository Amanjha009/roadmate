# RoadMate India 🏍️

> **Safety-first motorcycle touring app for Indian riders**

RoadMate India is an open-source, community-driven motorcycle touring platform purpose-built for the rugged, diverse, and unpredictable roads of the Indian subcontinent. Whether you are navigating remote high-altitude mountain passes in Ladakh and Spiti, cruising the coastal stretches of Konkan, or exploring the ghats of the Western Ghats, RoadMate provides intelligent navigation, crowd-sourced hazard intelligence, live convoy coordination, and an unyielding safety net.

---

## 🏗️ Architecture Overview

RoadMate India follows a modern, decoupled micro-architecture combining a high-performance asynchronous backend, cross-platform mobile client, geospatial database engine, and local-first offline syncing.

```
                  ┌────────────────────────────────────────┐
                  │          Flutter Mobile App            │
                  │   (iOS & Android / Offline-First)      │
                  └───────────────────┬────────────────────┘
                                      │ HTTPS / WSS
                                      ▼
                  ┌────────────────────────────────────────┐
                  │            FastAPI Backend             │
                  │    (Python 3.11 / AsyncIO / REST)      │
                  └───┬──────────────┬────────────────┬────┘
                      │              │                │
        ┌─────────────▼──────┐ ┌─────▼──────┐  ┌──────▼──────┐
        │ PostgreSQL 16 +    │ │  Redis 7   │  │ MinIO / S3  │
        │ PostGIS 3.4        │ │  (Cache &  │  │  (Storage & │
        │ (Spatial Database) │ │   Pub/Sub) │  │   Vault)    │
        └────────────────────┘ └────────────┘  └─────────────┘
                      │
        ┌─────────────▼──────┐
        │   OpenAI / LLM     │
        │  (Route Assistant) │
        └────────────────────┘
```

- **Mobile Client**: Flutter application providing fluid cross-platform performance, interactive offline mapping, Bluetooth sensor connectivity, and battery-optimized GPS tracking.
- **Backend Core**: FastAPI (asynchronous Python 3.11) delivering high-throughput REST APIs and WebSocket endpoints for real-time rider telemetry.
- **Geospatial Tier**: PostgreSQL 16 with PostGIS 3.4 extension enabling real-time spatial proximity queries, bounding-box hazard searches, and corridor risk analysis.
- **Cache & Pub/Sub**: Redis 7 managing volatile sessions, OTP lifecycle, and live convoy location distribution.
- **Media & Document Storage**: MinIO (local S3-compatible object store) and AWS S3 for secure document vault storage and hazard photo uploads.
- **AI Route Copilot**: OpenAI-compatible LLM layer generating curated itineraries, terrain difficulty assessments, and mountain pass travel advisories.

---

## ⚡ Quick Start

### Prerequisites
- [Docker](https://www.docker.com/) & Docker Compose
- [Python 3.11+](https://www.python.org/)
- [Flutter SDK](https://flutter.dev/) (3.x+)

### 1. Clone Repository
```bash
git clone https://github.com/your-org/roadmate-india.git
cd roadmate-india
```

### 2. Launch Local Infrastructure
Start PostGIS, Redis, MinIO, and Backend containers via Docker Compose:
```bash
docker-compose up -d
```
Verify all services are healthy:
```bash
docker-compose ps
```

* Services available:
  * **FastAPI Backend**: [http://localhost:8000](http://localhost:8000) (Interactive Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs))
  * **PostgreSQL (PostGIS)**: `localhost:5432` (`user: roadmate`, `db: roadmate`)
  * **Redis**: `localhost:6379`
  * **MinIO Console**: [http://localhost:9001](http://localhost:9001) (`user: roadmate`, `password: roadmate_dev_2024`)

### 3. Backend Local Development Setup
If running the Python service directly on your host machine:
```bash
cd backend

# Create and activate virtual environment
python -m venv venv
# Windows:
.\venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env

# Run database migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Mobile App Setup
```bash
cd mobile

# Fetch packages
flutter pub get

# Run on connected device / emulator
flutter run
```

---

## 🚀 MVP Features (9 Core Pillars)

1. **Rider Identity & Verified Onboarding**
   - Instant phone-based OTP authentication with developer bypass mode (`123456`).
   - Essential medical records (Blood Group, allergies) and primary emergency contact pairing.
   - Government ID and driving license verification flow for trust.

2. **Digital Garage & Maintenance Tracker**
   - Multi-motorcycle garage management (Make, model, CC, registration number).
   - Dynamic maintenance alerts based on odometer reading and elapsed time (engine oil, chain lube, brake pads, tire health).

3. **AI-Powered Route & Itinerary Planner**
   - Curated route generation factoring in motorcycle suitability, weather, and road conditions.
   - Tailored advice for high-altitude Himalayan passes (Khardung La, Rohtang, Chang La, Zoji La) including acclimatization warnings and fuel stop calculations.

4. **Group Ride & Convoy Coordination**
   - Real-time convoy management with designated hierarchy (**Captain**, **Sweep**, **Member**).
   - Live location broadcasting, check-in markers, automatic roll call, and rider fall-behind alerts.

5. **Crowdsourced PostGIS Hazard Alerts**
   - Geo-spatial hazard reporting: potholes, landslides, waterlogging/floods, roadblocks, black ice, and stray cattle.
   - Proximity radar that pushes real-time voice and visual alerts when approaching active hazards on your route.

6. **Instant Emergency SOS & Crash Detection**
   - One-touch emergency SOS triggering automated location broadcast to emergency contacts and nearby active riders.
   - Incident trail capturing recent coordinates and telemetry for rapid first-responder retrieval.

7. **Women Rider Safety & Unsafe Zone Reporting**
   - Anonymous reporting mechanism for poorly lit, isolated, or unsafe transit sections.
   - Community-verified safety ratings for night stops, dhabas, and fuel stations across national and state highways.

8. **Offline-First Resilience**
   - Zero-connectivity mode caching route geometry, emergency contacts, and vital medical info directly on the device.
   - Local queuing of reported hazards and ride metrics that automatically syncs when network connectivity resumes.

9. **Document Vault & Compliance Shield**
   - Encrypted local & cloud storage for vehicle Registration Certificate (RC), Insurance Policy, Pollution Under Control (PUC), and Driving License (DL).
   - Expiration notifications preventing costly traffic penalties.

---

## 🛠️ Tech Stack Details

| Domain | Technology | Description |
| :--- | :--- | :--- |
| **Backend Framework** | FastAPI (Python 3.11) | High-performance asynchronous REST API framework |
| **ORM & Database Driver** | SQLAlchemy 2.0 (Async) + asyncpg | Pure async database access with connection pooling |
| **Spatial Engine** | PostGIS 3.4 + GeoAlchemy2 | Spherical spatial types (`Geography(POINT, 4326)`), distance & bounding-box computations |
| **Database Migrations** | Alembic | Version-controlled schema evolutions |
| **Cache & Queue** | Redis 7 (Alpine) | Session storage, rate limiting, and pub/sub messaging |
| **Object Storage** | MinIO / AWS S3 | S3-compatible cloud storage for vehicle documents and media |
| **Authentication** | JWT (python-jose) + bcrypt | Stateless bearer authentication with refresh rotation |
| **AI / Machine Learning** | OpenAI API / GPT-4o | Intelligent route planning, packing recommendations & hazard summarization |
| **Mobile Client** | Flutter / Dart | Native compiled UI for Android and iOS |
| **Containerization** | Docker & Docker Compose | Multi-container reproducible development and deployment environment |

---

## 📁 Project Structure

```
passion/
├── docker-compose.yml           # Multi-container orchestration (PostGIS, Redis, MinIO, Backend)
├── .gitignore                   # Global ignores for Python, Flutter, Docker, IDEs
├── README.md                    # Project documentation
├── backend/
│   ├── Dockerfile               # Backend container specification
│   ├── .env                     # Local environment settings (git-ignored)
│   ├── .env.example             # Template for environment settings
│   ├── requirements.txt         # Python dependencies
│   ├── alembic.ini              # Alembic migration configuration
│   ├── alembic/
│   │   ├── env.py               # Alembic asynchronous runtime
│   │   └── versions/            # Database migration revisions
│   └── app/
│       ├── main.py              # FastAPI application entrypoint
│       ├── config.py            # Pydantic Settings configuration
│       ├── database.py          # SQLAlchemy async engine & sessionmaker
│       ├── api/
│       │   └── v1/              # Versioned API endpoints (auth, riders, bikes, trips, hazards, sos)
│       ├── core/                # Security, JWT, hashing, exceptions
│       ├── models/              # SQLAlchemy declarative models
│       │   ├── rider.py         # Rider, OTP, Emergency Contacts, Verification
│       │   ├── bike.py          # Motorcycle & Maintenance Reminders
│       │   ├── trip.py          # AI Trip Planning & Waypoints
│       │   ├── group_ride.py    # Group Convoy & Membership
│       │   ├── hazard.py        # PostGIS Road Hazard Reports
│       │   ├── sos.py           # Emergency SOS & Incident Trail
│       │   └── safety.py        # Unsafe Area Community Reports
│       ├── schemas/             # Pydantic request/response schemas
│       └── services/            # Business logic, S3 client, AI route generator
└── mobile/                      # Flutter mobile application
    ├── lib/                     # Application source code
    ├── pubspec.yaml             # Dart dependencies
    └── assets/                  # Icons, map styles, and static assets
```

---

## 🔐 Environment Variables Reference

The backend reads configuration settings from environment variables or a `.env` file located in `backend/.env`.

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `DATABASE_URL` | `postgresql+asyncpg://roadmate:roadmate_dev_2024@localhost:5432/roadmate` | Async PostgreSQL connection string with PostGIS enabled |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis instance connection URL |
| `JWT_SECRET_KEY` | `change-this-to-a-random-secret-in-production` | Secret cryptographic key for signing JWT tokens |
| `JWT_ALGORITHM` | `HS256` | JWT signing algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access token lifespan in minutes |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | `30` | Refresh token lifespan in days |
| `S3_ENDPOINT_URL` | `http://localhost:9000` | S3-compatible service endpoint (e.g. MinIO) |
| `S3_ACCESS_KEY` | `roadmate` | Access key for S3/MinIO bucket |
| `S3_SECRET_KEY` | `roadmate_dev_2024` | Secret key for S3/MinIO bucket |
| `S3_BUCKET_NAME` | `roadmate-uploads` | S3 bucket name for attachments & documents |
| `S3_REGION` | `us-east-1` | S3 bucket region |
| `LLM_API_BASE_URL` | `https://api.openai.com/v1` | Base URL for OpenAI-compatible LLM endpoint |
| `LLM_API_KEY` | `your-api-key-here` | API key for LLM itinerary and safety copilot |
| `LLM_MODEL` | `gpt-4o` | Model identifier used for route planning |
| `OTP_DEV_MODE` | `true` | When true, mock OTP verification bypass is enabled |
| `OTP_DEV_CODE` | `123456` | Fixed OTP passcode when `OTP_DEV_MODE` is enabled |
| `APP_NAME` | `RoadMate India` | Display name of the application |
| `APP_ENV` | `development` | Deployment environment (`development`, `staging`, `production`) |
| `DEBUG` | `true` | Verbose logging and exception tracebacks |

---

## 🔄 Automatic GitHub Sync

RoadMate includes an automated continuous sync daemon that monitors the workspace, debounces active edits, and automatically commits and pushes changes to GitHub:

```bash
# Check auto-sync status & view recent syncs
./scripts/auto_sync.sh status

# Start / stop the background daemon
./scripts/auto_sync.sh start
./scripts/auto_sync.sh stop

# Tail live sync logs
./scripts/auto_sync.sh logs
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE). Feel free to use, modify, and distribute with proper attribution.

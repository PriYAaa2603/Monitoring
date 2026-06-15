# MySQL / MariaDB Multi-Instance Monitoring

A local Docker environment that runs **3 MariaDB instances**, **Prometheus mysqld exporters**, **sysbench OLTP load**, **Prometheus**, and **Grafana** — all orchestrated with a single `docker compose up -d`.

## Architecture

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ mysql-instance-1│  │ mysql-instance-2│  │ mysql-instance-3│
│   :33061        │  │   :33062        │  │   :33063        │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
┌────────▼────────┐  ┌────────▼────────┐  ┌────────▼────────┐
│mysqld-exporter-1│  │mysqld-exporter-2│  │mysqld-exporter-3│
│   :9104         │  │   :9105         │  │   :9106         │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │    Prometheus     │
                    │      :9090        │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │     Grafana       │
                    │      :3000        │
                    └───────────────────┘

         ┌──────────────────────────────────┐
         │ sysbench (continuous OLTP load)  │
         │  → all 3 instances (diff threads)│
         └──────────────────────────────────┘
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (Docker Desktop on Windows/macOS, or Docker Engine on Linux)
- [Docker Compose](https://docs.docker.com/compose/) v2+

## Quick Start

```bash
cd Monitoring
docker compose up -d --build
```

Wait 1–2 minutes for MariaDB init scripts and sysbench schema preparation to complete.

| Service | URL / Port |
|---------|------------|
| **Grafana** | http://localhost:3000 |
| **Prometheus** | http://localhost:9090 |
| **MariaDB instance 1** | `localhost:33061` |
| **MariaDB instance 2** | `localhost:33062` |
| **MariaDB instance 3** | `localhost:33063` |
| **Exporter 1** | http://localhost:9104/metrics |
| **Exporter 2** | http://localhost:9105/metrics |
| **Exporter 3** | http://localhost:9106/metrics |

## Default Credentials

| Component | Username | Password |
|-----------|----------|----------|
| Grafana | `admin` | `admin` |
| MariaDB root | `root` | `rootpassword` |
| Monitoring user (exporter) | `exporter` | `exporterpassword` |

## Sample Databases

Each MariaDB instance is initialized with:

| Database | Tables | Description |
|----------|--------|-------------|
| `ecommerce` | `customers`, `orders` | Sample retail data |
| `analytics` | `page_views`, `daily_stats` | Sample analytics data |
| `sbtest` | (created by sysbench) | OLTP benchmark tables |

Init scripts live in `mariadb/init/`.

## Grafana Dashboard

After login, open **Dashboards → MySQL Monitoring → MySQL / MariaDB Multi-Instance Monitoring**.

Panels include:

- **MySQL Instance Status** — `mysql_up` per instance (UP/DOWN)
- **Databases per Instance** — table count grouped by schema
- **Database Size per Instance** — storage per schema
- **Query Throughput** — queries/sec per instance
- **Threads Running** — active threads per instance
- **Connections** — open connections per instance
- **Command Rates** — SELECT / INSERT / UPDATE / DELETE per instance

Because each instance runs sysbench with a different thread count (4 / 8 / 2 by default), load panels show visibly different activity.

## Sysbench Load Configuration

Configure via environment variables in `.env` or inline:

```bash
# Example: heavier load on instance 2, lighter on instance 3
SYSBENCH_THREADS_1=4 SYSBENCH_THREADS_2=16 SYSBENCH_THREADS_3=2 docker compose up -d
```

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSBENCH_THREADS_1` | `4` | Worker threads for mysql-instance-1 |
| `SYSBENCH_THREADS_2` | `8` | Worker threads for mysql-instance-2 |
| `SYSBENCH_THREADS_3` | `2` | Worker threads for mysql-instance-3 |
| `SYSBENCH_TABLES` | `4` | Number of sbtest tables per instance |
| `SYSBENCH_TABLE_SIZE` | `1000` | Rows per table |
| `SYSBENCH_REPORT_INTERVAL` | `10` | Seconds between sysbench reports |
| `SYSBENCH_TIME` | `0` | Seconds per run cycle (`0` = 3600s cycles, restarted indefinitely) |

Copy `.env.example` to `.env` to customize defaults:

```bash
cp .env.example .env
```

## Useful Commands

```bash
# Start everything
docker compose up -d --build

# View logs
docker compose logs -f sysbench
docker compose logs -f mysql-instance-1

# Check container health
docker compose ps

# Stop (keep data volumes)
docker compose down

# Stop and remove all data
docker compose down -v
```

## Connect to a Database

```bash
# Instance 1
mysql -h 127.0.0.1 -P 33061 -u root -prootpassword

# List databases
mysql -h 127.0.0.1 -P 33061 -u root -prootpassword -e "SHOW DATABASES;"
```

## Project Structure

```
Monitoring/
├── docker-compose.yml
├── .env.example
├── README.md
├── mariadb/
│   └── init/
│       ├── 01-monitoring-user.sql
│       ├── 02-ecommerce.sql
│       └── 03-analytics.sql
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   ├── dashboards/
│   │   └── mysql-monitoring.json
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboards.yml
│       └── datasources/
│           └── prometheus.yml
└── sysbench/
    ├── Dockerfile
    └── run-load.sh
```

## Troubleshooting

**Grafana panels show "No data"**
- Wait 2–3 minutes after first start for exporters and sysbench to populate metrics.
- Check Prometheus targets: http://localhost:9090/targets — all 3 mysqld jobs should be UP.

**sysbench keeps restarting**
- Check logs: `docker compose logs sysbench`
- Ensure MariaDB instances are healthy: `docker compose ps`

**Port conflicts**
- Edit host port mappings in `docker-compose.yml` if 3000, 9090, 33061–33063, or 9104–9106 are already in use.

**Reset everything**
```bash
docker compose down -v
docker compose up -d --build
```

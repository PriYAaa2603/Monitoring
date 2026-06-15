#!/bin/bash
set -euo pipefail

THREADS_1="${SYSBENCH_THREADS_1:-4}"
THREADS_2="${SYSBENCH_THREADS_2:-8}"
THREADS_3="${SYSBENCH_THREADS_3:-2}"
TABLES="${SYSBENCH_TABLES:-4}"
TABLE_SIZE="${SYSBENCH_TABLE_SIZE:-1000}"
REPORT_INTERVAL="${SYSBENCH_REPORT_INTERVAL:-10}"
RUN_TIME="${SYSBENCH_TIME:-0}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpassword}"

INSTANCES=(
  "mysql-instance-1:${THREADS_1}"
  "mysql-instance-2:${THREADS_2}"
  "mysql-instance-3:${THREADS_3}"
)

log() {
  echo "[sysbench] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

wait_for_db() {
  local host="$1"
  log "Waiting for ${host}..."
  until mysqladmin ping -h "${host}" -u root -p"${MYSQL_ROOT_PASSWORD}" --silent 2>/dev/null; do
    sleep 2
  done
  log "${host} is ready"
}

prepare_db() {
  local host="$1"
  log "Preparing sbtest schema on ${host}"
  sysbench /usr/share/sysbench/oltp_read_write.lua \
    --db-driver=mysql \
    --mysql-host="${host}" \
    --mysql-user=root \
    --mysql-password="${MYSQL_ROOT_PASSWORD}" \
    --tables="${TABLES}" \
    --table-size="${TABLE_SIZE}" \
    prepare
}

run_load() {
  local host="$1"
  local threads="$2"
  local cycle_time=3600

  if [ "${RUN_TIME}" -gt 0 ]; then
    cycle_time="${RUN_TIME}"
  fi

  log "Starting OLTP load on ${host} with ${threads} threads (cycle=${cycle_time}s)"

  while true; do
    sysbench /usr/share/sysbench/oltp_read_write.lua \
      --db-driver=mysql \
      --mysql-host="${host}" \
      --mysql-user=root \
      --mysql-password="${MYSQL_ROOT_PASSWORD}" \
      --tables="${TABLES}" \
      --table-size="${TABLE_SIZE}" \
      --threads="${threads}" \
      --report-interval="${REPORT_INTERVAL}" \
      --time="${cycle_time}" \
      run || log "Load run on ${host} exited; restarting in 5s"
    sleep 5
  done
}

for entry in "${INSTANCES[@]}"; do
  host="${entry%%:*}"
  wait_for_db "${host}"
done

for entry in "${INSTANCES[@]}"; do
  host="${entry%%:*}"
  prepare_db "${host}"
done

for entry in "${INSTANCES[@]}"; do
  host="${entry%%:*}"
  threads="${entry##*:}"
  run_load "${host}" "${threads}" &
done

log "All sysbench workers started"
wait

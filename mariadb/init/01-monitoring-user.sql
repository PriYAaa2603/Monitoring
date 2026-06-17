-- Monitoring user for Prometheus mysqld_exporter
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY 'exporterpassword';
GRANT PROCESS, REPLICATION CLIENT, SLAVE MONITOR, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;

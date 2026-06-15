CREATE DATABASE IF NOT EXISTS analytics;
USE analytics;

CREATE TABLE IF NOT EXISTS page_views (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  page_url VARCHAR(255) NOT NULL,
  visitor_id VARCHAR(36) NOT NULL,
  viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_viewed_at (viewed_at)
);

CREATE TABLE IF NOT EXISTS daily_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  stat_date DATE NOT NULL UNIQUE,
  page_views INT DEFAULT 0,
  unique_visitors INT DEFAULT 0
);

INSERT INTO page_views (page_url, visitor_id) VALUES
  ('/home', 'visitor-001'),
  ('/products', 'visitor-002'),
  ('/about', 'visitor-001'),
  ('/contact', 'visitor-003'),
  ('/products/widget-a', 'visitor-004'),
  ('/blog', 'visitor-002');

INSERT INTO daily_stats (stat_date, page_views, unique_visitors) VALUES
  ('2026-06-01', 1250, 340),
  ('2026-06-02', 1380, 395),
  ('2026-06-03', 1102, 310),
  ('2026-06-04', 1520, 420),
  ('2026-06-05', 980, 275);

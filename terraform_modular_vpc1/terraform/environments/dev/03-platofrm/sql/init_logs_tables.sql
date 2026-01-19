-- Tabla para logs de Zeek (conn.log principalmente)
CREATE TABLE IF NOT EXISTS zeek_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    src_ip VARCHAR(45),
    dst_ip VARCHAR(45),
    src_port INT,
    dst_port INT,
    protocol VARCHAR(10),
    bytes_sent BIGINT DEFAULT 0,
    bytes_received BIGINT DEFAULT 0,
    duration FLOAT DEFAULT 0,
    log_type VARCHAR(50) DEFAULT 'unknown',
    service VARCHAR(50),
    conn_state VARCHAR(10),
    raw_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_timestamp (timestamp),
    INDEX idx_src_ip (src_ip),
    INDEX idx_dst_ip (dst_ip),
    INDEX idx_log_type (log_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla para logs de FlowMeter
CREATE TABLE IF NOT EXISTS flowmeter_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    src_ip VARCHAR(45),
    dst_ip VARCHAR(45),
    protocol VARCHAR(10),
    total_fwd_packets INT DEFAULT 0,
    total_bwd_packets INT DEFAULT 0,
    flow_duration FLOAT DEFAULT 0,
    flow_bytes_per_sec FLOAT DEFAULT 0,
    flow_packets_per_sec FLOAT DEFAULT 0,
    raw_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_timestamp (timestamp),
    INDEX idx_src_ip (src_ip),
    INDEX idx_dst_ip (dst_ip),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vista para queries rápidas en Grafana
CREATE OR REPLACE VIEW recent_zeek_logs AS
SELECT 
    timestamp,
    src_ip,
    dst_ip,
    protocol,
    bytes_sent,
    bytes_received,
    log_type,
    created_at
FROM zeek_logs
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY timestamp DESC;
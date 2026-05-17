CREATE TABLE IF NOT EXISTS player_trucking (
    citizenid VARCHAR(64) NOT NULL,
    xp INT NOT NULL DEFAULT 0,
    reputation INT NOT NULL DEFAULT 0,
    jobs_completed INT NOT NULL DEFAULT 0,
    total_earned INT NOT NULL DEFAULT 0,
    total_routes_cancelled INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (citizenid)
);

CREATE TABLE IF NOT EXISTS trucking_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    contract_id VARCHAR(64) NOT NULL,
    contract_type VARCHAR(32) NOT NULL,
    route_label VARCHAR(128) NOT NULL,
    vehicle_label VARCHAR(128) NOT NULL,
    payout INT NOT NULL DEFAULT 0,
    xp INT NOT NULL DEFAULT 0,
    reputation INT NOT NULL DEFAULT 0,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS trucking_garage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    vehicle_type VARCHAR(32) NOT NULL,
    vehicle_index INT NOT NULL DEFAULT 1,
    vehicle_label VARCHAR(128) NOT NULL,
    vehicle_model VARCHAR(64) NOT NULL,
    plate VARCHAR(16) NOT NULL,
    props LONGTEXT NULL,
    stored TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_trucking_garage_vehicle (citizenid, vehicle_type, vehicle_index)
);

CREATE TABLE IF NOT EXISTS player_trucking (
    citizenid VARCHAR(64) NOT NULL,
    driver_name VARCHAR(96) NULL DEFAULT NULL,
    xp INT NOT NULL DEFAULT 0,
    reputation INT NOT NULL DEFAULT 0,
    jobs_completed INT NOT NULL DEFAULT 0,
    completed_route_streak INT NOT NULL DEFAULT 0,
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

CREATE TABLE IF NOT EXISTS trucking_contractor_profiles (
    citizenid VARCHAR(64) NOT NULL,
    licensed TINYINT(1) NOT NULL DEFAULT 0,
    license_purchased_at TIMESTAMP NULL DEFAULT NULL,
    contractor_rep INT NOT NULL DEFAULT 0,
    daily_route_key VARCHAR(64) NULL DEFAULT NULL,
    daily_route_selected_at TIMESTAMP NULL DEFAULT NULL,
    daily_route_date VARCHAR(16) NULL DEFAULT NULL,
    daily_route_completed TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (citizenid)
);

CREATE TABLE IF NOT EXISTS trucking_contractor_vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    vehicle_type VARCHAR(32) NOT NULL,
    vehicle_index INT NOT NULL DEFAULT 1,
    vehicle_label VARCHAR(128) NOT NULL,
    vehicle_model VARCHAR(64) NOT NULL,
    plate VARCHAR(16) NOT NULL,
    props LONGTEXT NULL,
    fuel FLOAT NOT NULL DEFAULT 100,
    engine_health FLOAT NOT NULL DEFAULT 1000,
    body_health FLOAT NOT NULL DEFAULT 1000,
    original_price INT NOT NULL DEFAULT 0,
    mileage FLOAT NOT NULL DEFAULT 0,
    stored TINYINT(1) NOT NULL DEFAULT 1,
    out_state TINYINT(1) NOT NULL DEFAULT 0,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_trucking_contractor_plate (plate),
    KEY index_trucking_contractor_owner (citizenid)
);

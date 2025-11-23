-- Create Keyspace if not exists
CREATE KEYSPACE IF NOT EXISTS ride
WITH REPLICATION = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

USE ride;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY,
    full_name TEXT,
    phone_number TEXT,
    email TEXT,
    password TEXT,
    user_type TEXT, -- 'passenger' or 'driver'
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Create index on email for login
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);

-- Refresh tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    token TEXT PRIMARY KEY,
    user_id UUID,
    expires_at TIMESTAMP,
    created_at TIMESTAMP,
    is_revoked BOOLEAN DEFAULT false,
    replaced_by_token TEXT
);

-- Create index on user_id for token management
CREATE INDEX IF NOT EXISTS refresh_tokens_user_id_idx ON refresh_tokens(user_id);

-- Vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id UUID PRIMARY KEY,
    driver_id UUID,
    vehicle_type TEXT, -- 'bike', 'car', 'business'
    brand TEXT,
    model TEXT,
    color TEXT,
    license_plate TEXT,
    status TEXT DEFAULT 'active', -- 'active', 'inactive', 'maintenance'
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Drivers table
CREATE TABLE IF NOT EXISTS drivers (
    driver_id UUID PRIMARY KEY,
    user_id UUID,
    license_number TEXT,
    license_expiry TIMESTAMP,
    vehicle_id UUID,
    current_location_lat DOUBLE,
    current_location_lng DOUBLE,
    is_available BOOLEAN DEFAULT true,
    online_status TEXT DEFAULT 'offline', -- 'online', 'offline', 'busy'
    rating DOUBLE DEFAULT 5.0,
    total_earnings DECIMAL DEFAULT 0,
    completed_trips INT DEFAULT 0,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Main rides table
CREATE TABLE IF NOT EXISTS rides (
    ride_id UUID PRIMARY KEY,
    passenger_id UUID,
    driver_id UUID,
    status TEXT, -- 'requesting', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled'
    pickup_location_lat DOUBLE,
    pickup_location_lng DOUBLE,
    pickup_address TEXT,
    dropoff_location_lat DOUBLE,
    dropoff_location_lng DOUBLE,
    dropoff_address TEXT,
    vehicle_type TEXT, -- 'bike', 'car', 'business'
    estimated_distance DOUBLE,
    actual_distance DOUBLE,
    estimated_duration INT,
    actual_duration INT,
    base_fare DECIMAL,
    distance_fare DECIMAL,
    time_fare DECIMAL,
    surge_fare DECIMAL,
    discount DECIMAL,
    total_fare DECIMAL,
    payment_method TEXT, -- 'cash', 'card', 'ewallet'
    payment_status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
    promo_code TEXT,
    created_at TIMESTAMP,
    accepted_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    driver_rating INT,
    passenger_rating INT,
    notes TEXT
);

-- Rides by passenger (for passenger's ride history)
CREATE TABLE IF NOT EXISTS rides_by_passenger (
    passenger_id UUID,
    created_at TIMESTAMP,
    ride_id UUID,
    status TEXT,
    pickup_address TEXT,
    dropoff_address TEXT,
    total_fare DECIMAL,
    PRIMARY KEY (passenger_id, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);

-- Rides by driver (for driver's ride history)
CREATE TABLE IF NOT EXISTS rides_by_driver (
    driver_id UUID,
    created_at TIMESTAMP,
    ride_id UUID,
    status TEXT,
    pickup_address TEXT,
    dropoff_address TEXT,
    total_fare DECIMAL,
    PRIMARY KEY (driver_id, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);

-- Rides by status (for finding available rides)
CREATE TABLE IF NOT EXISTS rides_by_status (
    status TEXT,
    created_at TIMESTAMP,
    ride_id UUID,
    passenger_id UUID,
    pickup_location_lat DOUBLE,
    pickup_location_lng DOUBLE,
    vehicle_type TEXT,
    total_fare DECIMAL,
    PRIMARY KEY (status, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);

-- Driver locations (for real-time tracking)
CREATE TABLE IF NOT EXISTS driver_locations (
    driver_id UUID,
    updated_at TIMESTAMP,
    latitude DOUBLE,
    longitude DOUBLE,
    is_available BOOLEAN DEFAULT true,
    vehicle_type TEXT,
    PRIMARY KEY (driver_id, updated_at)
) WITH CLUSTERING ORDER BY (updated_at DESC);

-- Available drivers by location (for spatial queries using geohash)
CREATE TABLE IF NOT EXISTS drivers_by_location (
    geohash TEXT, -- Geohash for spatial indexing
    driver_id UUID,
    latitude DOUBLE,
    longitude DOUBLE,
    is_available BOOLEAN,
    rating DOUBLE,
    updated_at TIMESTAMP,
    PRIMARY KEY (geohash, driver_id)
);

-- Driver profiles
CREATE TABLE IF NOT EXISTS driver_profiles (
    driver_id UUID PRIMARY KEY,
    full_name TEXT,
    phone_number TEXT,
    email TEXT,
    license_number TEXT,
    vehicle_brand TEXT,
    vehicle_model TEXT,
    vehicle_color TEXT,
    vehicle_plate TEXT,
    vehicle_type TEXT,
    rating DECIMAL,
    total_rides INT DEFAULT 0,
    status TEXT DEFAULT 'offline', -- 'online', 'offline', 'busy'
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Ratings and reviews
CREATE TABLE IF NOT EXISTS ride_ratings (
    ride_id UUID,
    rated_by UUID, -- user_id who gave the rating
    rated_to UUID, -- user_id who received the rating
    rating INT, -- 1-5 stars
    review TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (ride_id, rated_by)
);

-- Payment transactions
CREATE TABLE IF NOT EXISTS payments (
    payment_id UUID PRIMARY KEY,
    ride_id UUID,
    passenger_id UUID,
    driver_id UUID,
    amount DECIMAL,
    payment_method TEXT,
    status TEXT, -- 'pending', 'completed', 'failed', 'refunded'
    transaction_id TEXT, -- External payment gateway transaction ID
    created_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Promo codes
CREATE TABLE IF NOT EXISTS promo_codes (
    code TEXT PRIMARY KEY,
    description TEXT,
    discount_type TEXT, -- 'percentage', 'fixed'
    discount_value DECIMAL,
    min_fare DECIMAL,
    max_discount DECIMAL,
    usage_limit INT,
    used_count INT DEFAULT 0,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP
);

-- User promo code usage
CREATE TABLE IF NOT EXISTS user_promo_usage (
    user_id UUID,
    promo_code TEXT,
    ride_id UUID,
    used_at TIMESTAMP,
    discount_amount DECIMAL,
    PRIMARY KEY (user_id, promo_code)
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    notification_id UUID,
    user_id UUID,
    type TEXT, -- 'ride_request', 'ride_accepted', 'ride_completed', etc.
    title TEXT,
    message TEXT,
    data TEXT, -- JSON data for additional info
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP,
    PRIMARY KEY (user_id, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);

-- Create additional indexes
CREATE INDEX IF NOT EXISTS rides_passenger_id_idx ON rides(passenger_id);
CREATE INDEX IF NOT EXISTS rides_driver_id_idx ON rides(driver_id);
CREATE INDEX IF NOT EXISTS rides_status_idx ON rides(status);
CREATE INDEX IF NOT EXISTS driver_locations_is_available_idx ON driver_locations(is_available);
CREATE INDEX IF NOT EXISTS payments_ride_id_idx ON payments(ride_id);
CREATE INDEX IF NOT EXISTS drivers_user_id_idx ON drivers(user_id);
CREATE INDEX IF NOT EXISTS drivers_is_available_idx ON drivers(is_available);
CREATE INDEX IF NOT EXISTS vehicles_driver_id_idx ON vehicles(driver_id);
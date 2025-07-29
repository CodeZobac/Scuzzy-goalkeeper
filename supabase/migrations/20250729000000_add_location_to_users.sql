-- Add location columns to users table
ALTER TABLE public.users 
ADD COLUMN latitude DOUBLE PRECISION,
ADD COLUMN longitude DOUBLE PRECISION;

-- Create index for location-based queries
CREATE INDEX idx_users_location ON public.users USING btree (latitude, longitude);

-- Add function to calculate distance between two points (Haversine formula)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN (
        6371 * acos(
            cos(radians(lat1)) * 
            cos(radians(lat2)) * 
            cos(radians(lon2) - radians(lon1)) + 
            sin(radians(lat1)) * 
            sin(radians(lat2))
        )
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to get nearby goalkeepers
CREATE OR REPLACE FUNCTION get_nearby_goalkeepers(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 50
) RETURNS TABLE (
    id UUID,
    name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
    is_goalkeeper BOOLEAN,
    price_per_game NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.name,
        u.latitude,
        u.longitude,
        calculate_distance(user_lat, user_lon, u.latitude, u.longitude) as distance_km,
        u.is_goalkeeper,
        u.price_per_game
    FROM public.users u
    WHERE 
        u.is_goalkeeper = true
        AND u.latitude IS NOT NULL 
        AND u.longitude IS NOT NULL
        AND calculate_distance(user_lat, user_lon, u.latitude, u.longitude) <= radius_km
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;
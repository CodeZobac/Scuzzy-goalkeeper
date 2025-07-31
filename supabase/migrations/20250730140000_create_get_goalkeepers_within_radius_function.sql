CREATE OR REPLACE FUNCTION get_goalkeepers_within_radius(
  lat double precision,
  long double precision,
  radius double precision
)
RETURNS SETOF users AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM users
  WHERE
    is_goalkeeper = true AND
    latitude IS NOT NULL AND
    longitude IS NOT NULL AND
    ST_DWithin(
      ST_MakePoint(longitude, latitude)::geography,
      ST_MakePoint(long, lat)::geography,
      radius
    );
END;
$$ LANGUAGE plpgsql;

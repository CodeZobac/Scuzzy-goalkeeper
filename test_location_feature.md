# Location-Based Goalkeeper Search - Testing Guide

## Overview

This document provides a testing guide for the newly implemented location-based goalkeeper search feature.

## Features Implemented

### 1. Database Changes

- ✅ Added `latitude` and `longitude` columns to users table
- ✅ Created `calculate_distance` function using Haversine formula
- ✅ Created `get_nearby_goalkeepers` function for proximity-based queries
- ✅ Added database index for location-based queries

### 2. Model Updates

- ✅ Updated `UserProfile` model with location fields
- ✅ Added distance calculation methods
- ✅ Updated serialization methods (`toMap`, `fromMap`)

### 3. Services

- ✅ Created `LocationService` for GPS operations
- ✅ Created `GoalkeeperSearchService` for location-based searches
- ✅ Integrated with existing Supabase client

### 4. UI Components

- ✅ Updated `CreateAnnouncementScreen` to use location-based filtering
- ✅ Created `LocationUpdateWidget` for user location management
- ✅ Added distance display in goalkeeper selection

## Testing Steps

### 1. Database Testing

The database functions have been tested and are working correctly:

```sql
-- Test distance calculation (NY to LA ≈ 3936 km)
SELECT calculate_distance(40.7128, -74.0060, 34.0522, -118.2437) as distance_km;
-- Result: 3935.74625460972

-- Test nearby goalkeepers from Lisbon
SELECT * FROM get_nearby_goalkeepers(38.7223, -9.1393, 100);
-- Returns goalkeepers in Lisbon with 0 km distance
```

### 2. App Testing

#### Prerequisites

1. Ensure location permissions are granted
2. Test on a physical device (GPS required)
3. Have test goalkeeper accounts with location data

#### Test Scenarios

**Scenario 1: Create Announcement with Goalkeeper Hiring**

1. Open the app and navigate to "Create Announcement"
2. Fill in basic announcement details
3. Check "Contratar guarda-redes" checkbox
4. Allow location permissions when prompted
5. Verify that nearby goalkeepers appear in the dropdown
6. Verify that distances are displayed correctly
7. Select a goalkeeper and create the announcement

**Scenario 2: Location Update**

1. Navigate to user profile
2. Use the LocationUpdateWidget to set/update location
3. Verify location is saved to database
4. Test that updated location affects goalkeeper search results

**Scenario 3: Fallback Behavior**

1. Test with location services disabled
2. Verify app falls back to showing all goalkeepers
3. Test with no location permissions
4. Verify graceful error handling

## Sample Data

The following test data has been added to the database:

| Name           | City      | Latitude | Longitude | Price |
| -------------- | --------- | -------- | --------- | ----- |
| Bruno          | Albufeira | 37.0893  | -8.2446   | €20   |
| João Silva     | Lisboa    | 38.7223  | -9.1393   | €30   |
| Miguel Santos  | Porto     | 41.1579  | -8.6291   | €35   |
| Pedro Costa    | Lisboa    | 38.7223  | -9.1393   | €25   |
| André Ferreira | Coimbra   | 40.2033  | -8.4103   | €28   |

## Expected Results

### From Lisbon (38.7223, -9.1393):

- João Silva: 0 km
- Pedro Costa: 0 km
- André Ferreira: ~108 km
- Miguel Santos: ~274 km
- Bruno: ~454 km

### Performance

- Database queries should complete in <100ms
- Location acquisition should complete in <10s
- UI should remain responsive during location operations

## Known Limitations

1. Requires GPS-enabled device for testing
2. Location accuracy depends on device capabilities
3. Indoor testing may have reduced GPS accuracy
4. Requires internet connection for database queries

## Next Steps

1. Test on multiple devices
2. Add unit tests for distance calculations
3. Add integration tests for location services
4. Consider adding location caching for better performance
5. Add location update prompts for users without location data

CREATE INDEX IF NOT EXISTS hotel_bookings_city_index
    ON hotel_bookings(city);

CREATE INDEX IF NOT EXISTS hotel_bookings_created_at_desc_index
    ON hotel_bookings(created_at DESC);

CREATE INDEX IF NOT EXISTS hotel_bookings_organization_id_index
    ON hotel_bookings(organization_id);

CREATE INDEX IF NOT EXISTS hotel_bookings_booking_status_index
    ON hotel_bookings(booking_status);

CREATE INDEX IF NOT EXISTS hotel_bookings_organization_status_created_at_index
    ON hotel_bookings(organization_id, booking_status, created_at DESC);

CREATE INDEX IF NOT EXISTS booking_events_booking_id_created_at_index
    ON booking_events(booking_id, created_at DESC);

CREATE INDEX IF NOT EXISTS hotel_bookings_city_created_at_organization_status_index
    ON hotel_bookings(city, created_at DESC, organization_id, booking_status);
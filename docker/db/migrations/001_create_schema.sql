CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS hotel_bookings (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_reference VARCHAR(30) NOT NULL UNIQUE,
    organization_id UUID NOT NULL,
    guest_name VARCHAR(150) NOT NULL,
    guest_email VARCHAR(255) NOT NULL,
    hotel_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    room_type VARCHAR(50) NOT NULL,
    booking_status VARCHAR(30) NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT hotel_bookings_status_check
        CHECK (booking_status IN ('pending', 'confirmed', 'checked_in', 'completed', 'cancelled')),

    CONSTRAINT hotel_bookings_date_check
        CHECK (check_out_date > check_in_date),

    CONSTRAINT hotel_bookings_amount_check
        CHECK (total_amount >= 0)
);

CREATE TABLE IF NOT EXISTS booking_events (
    booking_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES hotel_bookings(booking_id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT booking_events_event_type_check
        CHECK (event_type IN (
            'booking_created',
            'payment_authorized',
            'booking_confirmed',
            'guest_checked_in',
            'guest_checked_out',
            'booking_cancelled'
        ))
);

CREATE OR REPLACE FUNCTION update_hotel_bookings_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_hotel_bookings_updated_at_trigger ON hotel_bookings;

CREATE TRIGGER update_hotel_bookings_updated_at_trigger
BEFORE UPDATE ON hotel_bookings
FOR EACH ROW
EXECUTE FUNCTION update_hotel_bookings_updated_at_column();
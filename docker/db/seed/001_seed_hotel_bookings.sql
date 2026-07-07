WITH organization_reference_data AS (
    SELECT ARRAY[
        '11111111-1111-1111-1111-111111111111'::uuid,
        '22222222-2222-2222-2222-222222222222'::uuid,
        '33333333-3333-3333-3333-333333333333'::uuid,
        '44444444-4444-4444-4444-444444444444'::uuid,
        '55555555-5555-5555-5555-555555555555'::uuid
    ] AS organization_ids
),
created_hotel_bookings AS (
    INSERT INTO hotel_bookings (
        booking_reference,
        organization_id,
        guest_name,
        guest_email,
        hotel_name,
        city,
        room_type,
        booking_status,
        check_in_date,
        check_out_date,
        total_amount,
        currency_code,
        created_at
    )
    SELECT
        'HB-' || TO_CHAR(100000 + generated_booking_number, 'FM999999') AS booking_reference,
        (
            SELECT organization_ids[((generated_booking_number - 1) % 5) + 1]
            FROM organization_reference_data
        ) AS organization_id,
        guest_name_values[((generated_booking_number - 1) % array_length(guest_name_values, 1)) + 1] AS guest_name,
        LOWER(REPLACE(guest_name_values[((generated_booking_number - 1) % array_length(guest_name_values, 1)) + 1], ' ', '.'))
            || generated_booking_number || '@example.com' AS guest_email,
        hotel_name_values[((generated_booking_number - 1) % array_length(hotel_name_values, 1)) + 1] AS hotel_name,
        city_values[((generated_booking_number - 1) % array_length(city_values, 1)) + 1] AS city,
        room_type_values[((generated_booking_number - 1) % array_length(room_type_values, 1)) + 1] AS room_type,
        booking_status_values[((generated_booking_number - 1) % array_length(booking_status_values, 1)) + 1] AS booking_status,
        CURRENT_DATE + ((generated_booking_number % 45) * INTERVAL '1 day') AS check_in_date,
        CURRENT_DATE + ((generated_booking_number % 45) * INTERVAL '1 day') + (((generated_booking_number % 5) + 1) * INTERVAL '1 day') AS check_out_date,
        ROUND((2500 + (generated_booking_number * 137.75))::numeric, 2) AS total_amount,
        'INR' AS currency_code,
        NOW() - ((generated_booking_number % 90) * INTERVAL '1 day') AS created_at
    FROM generate_series(1, 125) AS generated_booking_number
    CROSS JOIN LATERAL (
        SELECT
            ARRAY[
                'Aarav Sharma',
                'Diya Mehta',
                'Rohan Verma',
                'Sneha Iyer',
                'Kabir Khan',
                'Neha Gupta',
                'Arjun Singh',
                'Priya Nair',
                'Vikram Rao',
                'Ananya Das'
            ] AS guest_name_values,
            ARRAY[
                'Azure Grand',
                'Cloud Residency',
                'DevOps Suites',
                'Royal Container Inn',
                'Blue Pipeline Hotel',
                'Terraform Palace'
            ] AS hotel_name_values,
            ARRAY[
                'Delhi',
                'Mumbai',
                'Bengaluru',
                'Hyderabad',
                'Pune',
                'Chennai',
                'Jaipur',
                'Gurgaon'
            ] AS city_values,
            ARRAY[
                'standard',
                'deluxe',
                'premium',
                'suite'
            ] AS room_type_values,
            ARRAY[
                'pending',
                'confirmed',
                'checked_in',
                'completed',
                'cancelled'
            ] AS booking_status_values
    ) booking_seed_data
    ON CONFLICT (booking_reference) DO NOTHING
    RETURNING booking_id, booking_status
)
INSERT INTO booking_events (
    booking_id,
    event_type,
    event_payload,
    created_at
)
SELECT
    booking_id,
    CASE
        WHEN booking_status = 'pending' THEN 'booking_created'
        WHEN booking_status = 'confirmed' THEN 'booking_confirmed'
        WHEN booking_status = 'checked_in' THEN 'guest_checked_in'
        WHEN booking_status = 'completed' THEN 'guest_checked_out'
        WHEN booking_status = 'cancelled' THEN 'booking_cancelled'
    END AS event_type,
    jsonb_build_object('source', 'dev-seed-script', 'booking_status', booking_status),
    NOW()
FROM created_hotel_bookings;
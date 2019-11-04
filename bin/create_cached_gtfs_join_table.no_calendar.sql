BEGIN;

CREATE TABLE avg_daily_trips_across_shape_by_time_period(
  shape_id TEXT   PRIMARY KEY,
  amp_num_trips   REAL,
  midd_num_trips  REAL,
  pmp_num_trips   REAL,
  we_num_trips    REAL,
  ovn_num_trips   REAL
) WITHOUT ROWID;

WITH cte_trip_departure_times AS (
  SELECT
      trips.shape_id,
      trip_departure_time,
      1.0 AS avg_weekday_coverage,
      1.0 AS avg_weekend_coverage,
      1.0 AS avg_full_week_coverage
    FROM trips
      INNER JOIN (
        SELECT
            trip_id,
            MIN(departure_time) AS trip_departure_time
          FROM stop_times
          GROUP BY trip_id
      ) AS trip_start_times USING (trip_id)
)
  INSERT INTO avg_daily_trips_across_shape_by_time_period (
    shape_id,
    amp_num_trips,
    midd_num_trips,
    pmp_num_trips,
    we_num_trips,
    ovn_num_trips
  )
  SELECT
      all_shape_ids.shape_id,
      COALESCE(
        ROUND( amp.num_trips, 2),
        0
      ) AS amp_num_trips,
      COALESCE(
        ROUND( midd.num_trips, 2),
        0
      ) AS midd_num_trips,
      COALESCE(
        ROUND( pmp.num_trips, 2),
        0
      ) AS pmp_num_trips,
      COALESCE(
        ROUND( we.num_trips, 2),
        0
      ) AS we_num_trips,
      COALESCE(
        ROUND( ovn.num_trips, 2),
        0
      ) AS ovn_num_trips
    FROM (
        SELECT DISTINCT
            shape_id
          FROM cte_trip_departure_times
      ) AS all_shape_ids
      LEFT OUTER JOIN (
        SELECT
            shape_id,
            SUM(avg_weekday_coverage) AS num_trips
          FROM cte_trip_departure_times
          WHERE (
            ( trip_departure_time >= '06:00:00' )
            AND
            ( trip_departure_time < '10:00:00' )
          )
          GROUP BY shape_id
      ) AS amp USING (shape_id)
      LEFT OUTER JOIN (
        SELECT
            shape_id,
            SUM(avg_weekday_coverage) AS num_trips
          FROM cte_trip_departure_times
          WHERE (
            ( trip_departure_time >= '10:00:00' )
            AND
            ( trip_departure_time < '16:00:00' )
          )
          GROUP BY shape_id
      ) AS midd USING (shape_id)
      LEFT OUTER JOIN (
        SELECT
            shape_id,
            SUM(avg_weekday_coverage) AS num_trips
          FROM cte_trip_departure_times
          WHERE (
            ( trip_departure_time >= '16:00:00' )
            AND
            ( trip_departure_time < '20:00:00' )
          )
          GROUP BY shape_id
      ) AS pmp USING (shape_id)
      LEFT OUTER JOIN (
        SELECT
            shape_id,
            SUM(avg_weekend_coverage) AS num_trips
          FROM cte_trip_departure_times
          WHERE (
            ( trip_departure_time >= '06:00:00' )
            AND
            ( trip_departure_time < '20:00:00' )
          )
          GROUP BY shape_id
      ) AS we USING (shape_id)
      LEFT OUTER JOIN (
        SELECT
            shape_id,
            SUM(avg_full_week_coverage) AS num_trips
          FROM cte_trip_departure_times
          WHERE (
            ( trip_departure_time < '06:00:00' )
            OR
            ( trip_departure_time >= '20:00:00' )
          )
          GROUP BY shape_id
      ) AS ovn USING (shape_id)
;

COMMIT;

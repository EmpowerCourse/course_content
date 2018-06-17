CREATE OR REPLACE FUNCTION public.aggregate_unit_feed()
  RETURNS void AS
$BODY$ 
DECLARE 
v_start_point timestamp without time zone;
v_end_point timestamp without time zone;
rec_unit RECORD;
BEGIN

CREATE TEMPORARY TABLE tmp_aggregate_driver (
unit_id integer NOT NULL,
data_type_id integer NOT NULL,
start_at timestamp without time zone NOT NULL, 
end_at timestamp without time zone NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_aggregate_driver (unit_id, data_type_id, start_at, end_at)
SELECT f.unit_id, f.data_type_id, MIN(f.occurred_at) as start_at, MAX(f.occurred_at) as end_at
FROM unit_feed f LEFT JOIN unit_feed_aggregated a ON f.id = a.unit_feed_id
WHERE a.unit_feed_id IS NULL
GROUP BY f.unit_id, f.data_type_id;

FOR rec_unit IN
	SELECT unit_id
	FROM tmp_aggregate_driver
	GROUP BY unit_id
LOOP -- each unit to be refreshed
	v_start_point := (SELECT MIN(start_at) FROM tmp_aggregate_driver WHERE unit_id = rec_unit.unit_id);
	v_end_point := (SELECT MAX(end_at) FROM tmp_aggregate_driver WHERE unit_id = rec_unit.unit_id);

	WITH RECURSIVE driver(seq, range_start, range_end) AS 
	(
		SELECT 0, 
		v_start_point,
		v_start_point + INTERVAL '10 minutes'
		UNION ALL
		SELECT seq + 1, range_end, range_end + INTERVAL '10 minutes'
		FROM driver
		WHERE range_end < v_end_point
	),
	unit_data_types (unit_id, data_type_id) as (
		SELECT unit_id, data_type_id
		FROM tmp_aggregate_driver
		WHERE unit_id = rec_unit.unit_id
		GROUP BY unit_id, data_type_id
	)
	INSERT INTO unit_feed_sum_10min (unit_id, data_type_id, point_at, value)
	SELECT dt.unit_id, 
		dt.data_type_id, 
		d.range_start + INTERVAL '5 minutes', 
		(SELECT AVG(f.value) FROM unit_feed f
			WHERE f.unit_id = dt.unit_id
				AND f.data_type_id = dt.data_type_id
				AND f.occurred_at >= d.range_start
				AND f.occurred_at <= d.range_end)
	FROM driver d, unit_data_types dt
	WHERE d.seq > 0
		AND EXISTS(
			SELECT 1
			FROM unit_feed f
			WHERE f.unit_id = dt.unit_id
				AND f.data_type_id = dt.data_type_id
				AND f.occurred_at >= d.range_start
				AND f.occurred_at <= d.range_end
		);

	WITH RECURSIVE driver(seq, range_start, range_end) AS 
	(
		SELECT 0, 
			v_start_point,
			v_start_point + INTERVAL '1 hour'
		UNION ALL
		SELECT seq + 1, range_end, range_end + INTERVAL '1 hour'
			FROM driver
			WHERE range_end < v_end_point
	),
	unit_data_types (unit_id, data_type_id) as (
		SELECT unit_id, data_type_id
		FROM tmp_aggregate_driver
		WHERE unit_id = rec_unit.unit_id
		GROUP BY unit_id, data_type_id
	)
	INSERT INTO unit_feed_sum_1hr (unit_id, data_type_id, point_at, value)
	SELECT dt.unit_id, 
		dt.data_type_id, 
		d.range_start + INTERVAL '30 minutes', 
		(SELECT AVG(f.value) FROM unit_feed f
		WHERE f.unit_id = dt.unit_id
		  AND f.data_type_id = dt.data_type_id
		  AND f.occurred_at >= d.range_start
		  AND f.occurred_at <= d.range_end)
	FROM driver d, unit_data_types dt
	WHERE d.seq > 0
		AND EXISTS(
			SELECT 1 FROM unit_feed f
			WHERE f.unit_id = dt.unit_id
			  AND f.data_type_id = dt.data_type_id
			  AND f.occurred_at >= d.range_start
			  AND f.occurred_at <= d.range_end
		);
END LOOP;

INSERT INTO unit_feed_aggregated (unit_feed_id)
SELECT f.id
FROM unit_feed f INNER JOIN tmp_aggregate_driver p ON p.unit_id = f.unit_id
AND p.data_type_id = f.data_type_id
AND f.occurred_at >= p.start_at
AND f.occurred_at <= p.end_at
LEFT JOIN unit_feed_aggregated x ON x.unit_feed_id = f.id
WHERE x.unit_feed_id IS NULL;

DROP TABLE tmp_aggregate_driver;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.aggregate_unit_feed()
  OWNER TO aws_sa;

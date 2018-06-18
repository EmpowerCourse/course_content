CREATE OR REPLACE FUNCTION public.get_unit_chart_data(
    IN p_unit_id integer,
    IN p_user_tz character varying,
    IN p_from timestamp without time zone,
    IN p_to timestamp without time zone)
  RETURNS TABLE(burnerpoints text, oilpoints text, airpoints text, 
	levelpoints text, resetcount bigint, offcount bigint, runningcount bigint, 
	burneraboveisrunning integer, burneraboveisoff integer) AS
$BODY$
BEGIN

RETURN QUERY

SELECT array_to_string(
	array(
		SELECT '[' || 
			CAST(extract(epoch from f.occurred_at at time zone 'UTC' at time zone p_user_tz) * 1000 as varchar(20)) || ',' || 
			CAST(f.value as varchar(10)) || ']'
		FROM unit_feed f 
		WHERE f.unit_id = p_unit_id
			AND f.data_type_id = 0 -- BURNER
			AND f.occurred_at >= p_from
			AND f.occurred_at < p_to
		ORDER BY f.occurred_at
), ',') as burnerPoints,

array_to_string(
	array(
		SELECT '[' || 
			CAST(extract(epoch from f.occurred_at at time zone 'UTC' at time zone p_user_tz) * 1000 as varchar(20)) || ',' || 
			CAST(f.value as varchar(10)) || ']'
		FROM unit_feed f 
		WHERE f.unit_id = p_unit_id
			AND f.data_type_id = 2 -- OIL
			AND f.occurred_at >= p_from
			AND f.occurred_at < p_to
		ORDER BY f.occurred_at
), ',') as oilPoints,

array_to_string(
	array(
		SELECT '[' || 
			CAST(extract(epoch from f.occurred_at at time zone 'UTC' at time zone p_user_tz) * 1000 as varchar(20)) || ',' || 
			CAST(f.value as varchar(10)) || ']'
		FROM unit_feed f 
		WHERE f.unit_id = p_unit_id
			AND f.data_type_id = 1 -- AIR
			AND f.occurred_at >= p_from
			AND f.occurred_at < p_to
		ORDER BY f.occurred_at
), ',') as airPoints,

array_to_string(
	array(
		SELECT '[' || 
			CAST(extract(epoch from f.occurred_at at time zone 'UTC' at time zone p_user_tz) * 1000 as varchar(20)) || ',' || 
			CAST(f.value as varchar(10)) || ']'
		FROM unit_feed f 
		WHERE f.unit_id = p_unit_id
			AND f.data_type_id = 3 -- level
			AND f.occurred_at >= p_from
			AND f.occurred_at < p_to
		ORDER BY f.occurred_at
), ',') as levelPoints,

SUM(CASE WHEN range_name = 'In Reset' THEN 1 ELSE 0 END) as resetCount,
SUM(CASE WHEN range_name = 'Power Off' THEN 1 ELSE 0 END) as offCount,
SUM(CASE WHEN range_name = 'Running' THEN 1 ELSE 0 END) as runningCount,

(SELECT COALESCE(ur.mn, d.mn) 
FROM public.data_type_range_default d LEFT JOIN data_type_unit_range ur ON ur.unit_id = p_unit_id
	AND d.data_type_id = ur.data_type_id
	AND d.name = ur.name
WHERE d.data_type_id = 0
	AND d.name = 'Running') as burnerAboveIsRunning,

(SELECT COALESCE(ur.mn, d.mn) 
FROM public.data_type_range_default d LEFT JOIN data_type_unit_range ur ON ur.unit_id = p_unit_id
	AND d.data_type_id = ur.data_type_id
	AND d.name = ur.name
WHERE d.data_type_id = 0
	AND d.name = 'Power Off') as burnerAboveIsOff
FROM public.interpret_unit_feed(p_unit_id, 0, p_from, p_to);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_unit_chart_data(integer, character varying, timestamp without time zone, timestamp without time zone)
  OWNER TO aws_sa;

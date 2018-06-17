CREATE OR REPLACE FUNCTION public.interpret_unit_feed(
    IN p_unit_id integer,
    IN p_data_type_id integer,
    IN p_from timestamp without time zone,
    IN p_through timestamp without time zone)
  RETURNS TABLE(occurred_at timestamp without time zone, value integer, range_name character varying) AS
$BODY$
BEGIN

RETURN QUERY

SELECT f.occurred_at, f.value, COALESCE(ur.name, d.name) as range_name
FROM public.unit_feed f LEFT JOIN public.data_type_range_default d ON f.data_type_id = d.data_type_id
	LEFT JOIN data_type_unit_range ur ON ur.unit_id = f.unit_id
		AND f.data_type_id = ur.data_type_id
		AND ur.name = d.name
WHERE f.unit_id = p_unit_id
	AND f.data_type_id = p_data_type_id
	AND f.value >= COALESCE(ur.mn, d.mn)
	AND f.value <= COALESCE(ur.mx, d.mx)
	AND f.occurred_at >= p_from
	AND f.occurred_at <= p_through
ORDER BY f.occurred_at;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.interpret_unit_feed(integer, integer, timestamp without time zone, timestamp without time zone)
  OWNER TO aws_sa;

CREATE OR REPLACE FUNCTION public.analyze(
    p_pkg_id integer,
    p_performed_by_user_id integer,
    p_critical_z numeric)
  RETURNS integer AS
$BODY$
DECLARE 
v_project_id integer;
v_analysis_id integer;
v_executed_at timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
v_std_pkg_id integer;
v_allowed_variance_pct numeric(4,2);
v_min_sample_size integer;
BEGIN

SELECT a.allowed_variance_pct * 0.01, a.id, a.min_sample_size
INTO v_allowed_variance_pct, v_project_id, v_min_sample_size
FROM audit a INNER JOIN audit_data_package p ON p.audit_id = a.id
WHERE p.id = p_pkg_id;

SELECT MAX(code_standard_package_id)
INTO v_std_pkg_id
FROM focus_specialty
WHERE audit_id = v_project_id;

IF EXISTS(SELECT 1 FROM person_analysis WHERE project_pkg_id = p_pkg_id) THEN 
	DELETE FROM person_sample_analysis
	WHERE person_id IN (
	SELECT p.id FROM person p INNER JOIN person_analysis pa ON p.person_analysis_id = pa.id
	WHERE pa.project_pkg_id = p_pkg_id);

	DELETE FROM person_finding
	WHERE person_id IN (SELECT p.id FROM person_analysis pa INNER JOIN person p ON p.person_analysis_id = pa.id WHERE pa.project_pkg_id = p_pkg_id);

	DELETE FROM audit_person_asset
	WHERE person_id IN (SELECT p.id FROM person_analysis pa INNER JOIN person p ON p.person_analysis_id = pa.id WHERE pa.project_pkg_id = p_pkg_id);

	DELETE FROM person 
	WHERE person_analysis_id IN (SELECT pa.id FROM person_analysis pa WHERE project_pkg_id = p_pkg_id);

	DELETE FROM person_analysis WHERE project_pkg_id = p_pkg_id;
END IF;

INSERT INTO person_analysis (project_pkg_id, code_standard_package_id, performed_by_user_id, critical_z_high, critical_z_low, inserted_at, updated_at)
VALUES (p_pkg_id, v_std_pkg_id, p_performed_by_user_id, p_critical_z, p_critical_z, v_executed_at, v_executed_at)
	RETURNING id INTO v_analysis_id;

INSERT INTO person (person_analysis_id, project_focus_id, code, name)
SELECT v_analysis_id, s.id, a.person_id, COALESCE(MAX(a.person_full_name), '')
FROM project_data_row a INNER JOIN focus_specialty s ON s.proposed_code = a.specialty_code
	AND s.audit_id = v_project_id
WHERE a.project_pkg_id = p_pkg_id
GROUP BY a.specialty_code, s.id, a.person_id;

-- aggregate numbers at the procedure code level
INSERT INTO person_sample_analysis (person_id, project_focus_id, sample_code, sample_category_id, seq, 
	cnt, modifier_25_cnt, standard_cnt, standard_pct, standard_score)
SELECT p.id, p.project_focus_id, csr.sample_code, csr.sample_category_id, csr.seq, 
	COALESCE(x.procedure_cnt, 0), COALESCE(x.modifier_25_cnt, 0), csr.cnt, csr.state_pct, csr.seq * csr.state_pct as standard_score
FROM gold_standard_row csr INNER JOIN focus_specialty s ON csr.specialty_code = s.standard_code
		AND csr.code_standard_package_id = s.code_standard_package_id
	LEFT JOIN sample_code_group_override o ON o.specialty_code = csr.specialty_code
		AND o.code = csr.sample_code
	INNER JOIN procedure_category c ON c.id = COALESCE(o.sample_category_id, csr.sample_category_id)
	INNER JOIN person p ON s.id = p.project_focus_id
		AND p.person_analysis_id = v_analysis_id
	INNER JOIN person_analysis ss on ss.id = p.person_analysis_id
	LEFT JOIN (
		SELECT a.person_id,
			sm.standard_code as standard_specialty_code,
			c.code as sample_code,
			c.sample_category_id,
			SUM(CASE WHEN '25' IN (a.modifier_1, a.modifier_2, a.modifier_3) THEN 1 ELSE 0 END) as modifier_25_cnt,
			COUNT(*) as procedure_cnt
		FROM project_data_row a INNER JOIN sample_code c ON c.code = a.assigned_code
			INNER JOIN focus_specialty sm ON sm.proposed_code = a.specialty_code
		WHERE a.project_pkg_id = p_pkg_id
		GROUP BY a.person_id, sm.standard_code, c.code, c.sample_category_id
	) x ON csr.sample_code = x.sample_code
	AND csr.specialty_code = x.standard_specialty_code
	AND p.code = x.person_id
WHERE csr.code_standard_package_id = v_std_pkg_id
	AND ss.project_pkg_id = p_pkg_id;

-- get aggregate category counts for the code standard
UPDATE person_sample_analysis a SET standard_category_cnt = b.category_cnt
FROM (
	SELECT csr.sample_category_id, s.id as project_focus_id, SUM(csr.cnt) as category_cnt
	FROM gold_standard_row csr INNER JOIN focus_specialty s ON csr.specialty_code = s.standard_code
		AND csr.code_standard_package_id = s.code_standard_package_id
	WHERE csr.code_standard_package_id = v_std_pkg_id
	GROUP BY csr.sample_category_id, s.id
) b
WHERE a.sample_category_id = b.sample_category_id
	AND a.project_focus_id = b.project_focus_id;

-- get aggregate category counts for each person
UPDATE person_sample_analysis a SET category_cnt = b.total_cnt,
	cnt_adjustment = ROUND(b.total_cnt * v_allowed_variance_pct)
FROM (
	SELECT sample_category_id, person_id, SUM(cnt) as total_cnt
	FROM person_sample_analysis
	WHERE person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id)
	GROUP BY sample_category_id, person_id
) b
WHERE a.sample_category_id = b.sample_category_id
	AND a.person_id = b.person_id;

UPDATE person_sample_analysis SET 
	standard_p = CASE WHEN standard_category_cnt = 0 THEN 0.0 ELSE (CAST(standard_cnt as numeric(18,3)) / standard_category_cnt) END, 
	cnt_high = CASE WHEN cnt + cnt_adjustment > category_cnt THEN category_cnt ELSE cnt + cnt_adjustment END,
	cnt_low = CASE WHEN cnt - cnt_adjustment < 0 THEN 0 ELSE cnt - cnt_adjustment END
WHERE standard_category_cnt > v_min_sample_size
	AND category_cnt > v_min_sample_size
	AND person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id);

UPDATE person_sample_analysis SET 
	standard_p = CASE WHEN standard_category_cnt = 0 THEN 0.0 ELSE (CAST(standard_cnt as numeric(18,3)) / standard_category_cnt) END, 
	cnt_high = 0,
	cnt_low = 0
WHERE (standard_category_cnt <= v_min_sample_size OR category_cnt <= v_min_sample_size)
	AND person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id);

UPDATE person_sample_analysis SET p_high = CAST(cnt_high as numeric(18,3)) / category_cnt, 
	p_low = CAST(cnt_low as numeric(18,3)) / category_cnt
WHERE standard_category_cnt > v_min_sample_size
	AND category_cnt > v_min_sample_size
	AND person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id);

UPDATE person_sample_analysis SET 
	z_term_high_1 = CAST((standard_cnt + cnt_high) as numeric(18,3)) / (standard_category_cnt + category_cnt),
	z_term_low_1 = CAST((standard_cnt + cnt_low) as numeric(18,3)) / (standard_category_cnt + category_cnt),
	z_term_2 = (1.0 / standard_category_cnt) + (1.0 / category_cnt)
WHERE standard_category_cnt > v_min_sample_size
	AND category_cnt > v_min_sample_size
	AND person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id);

DELETE FROM person_sample_analysis 
WHERE standard_category_cnt > v_min_sample_size
	AND category_cnt > v_min_sample_size
	AND (z_term_high_1 = 1.0 OR z_term_low_1 = 1.0)
	AND person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id);

UPDATE person_sample_analysis SET 
	z_high = (p_high - standard_p) / sqrt(z_term_high_1 * (1.0 - z_term_high_1) * z_term_2), 
	z_low = (p_low - standard_p) / sqrt(z_term_low_1 * (1.0 - z_term_low_1) * z_term_2)
WHERE standard_category_cnt > v_min_sample_size
	AND category_cnt > v_min_sample_size;

-- update procedure code level aggregate conclusions
UPDATE person_sample_analysis r
	SET pct = case when rx.total_cnt > 0 then round((r.cnt / cast(rx.total_cnt as numeric(12,2)))*100.0, 1) else 0.0 end, 
		score = case when rx.total_cnt > 0 then round(((r.cnt / cast(rx.total_cnt as numeric(12,2)))*100.0) * r.seq, 1) else 0.0 end,
		overcoded = CASE WHEN r.z_low > p_critical_z THEN true ELSE false END,
		undercoded = CASE WHEN r.z_high < (p_critical_z * -1) THEN true ELSE false END
FROM (
	SELECT a.person_id, a.sample_category_id, SUM(a.cnt) as total_cnt
	FROM person_sample_analysis a
	WHERE person_id IN (select p.id from person p where p.person_analysis_id = v_analysis_id)
	GROUP BY a.person_id, a.sample_category_id
) rx
WHERE rx.person_id = r.person_id
	AND rx.sample_category_id = r.sample_category_id;

RETURN v_analysis_id;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.analyze_audit_package(integer, integer, numeric)
  OWNER TO aws_sa;

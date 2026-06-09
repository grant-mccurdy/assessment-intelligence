SELECT
    grade_level,
    course_id,
    course_name,
    course_track,
    COUNT(*) AS matched_students,
    ROUND(AVG(boy_score), 2) AS assignment_01_avg,
    ROUND(AVG(eoy_score), 2) AS assignment_02_avg,
    ROUND(AVG(observed_growth_delta), 2) AS avg_observed_growth_delta,
    ROUND(MIN(observed_growth_delta), 2) AS min_observed_growth_delta,
    ROUND(MAX(observed_growth_delta), 2) AS max_observed_growth_delta
FROM mart.student_readiness
WHERE present_boy
  AND present_eoy
  AND observed_growth_delta IS NOT NULL
GROUP BY
    grade_level,
    course_id,
    course_name,
    course_track
ORDER BY
    grade_level,
    course_id;

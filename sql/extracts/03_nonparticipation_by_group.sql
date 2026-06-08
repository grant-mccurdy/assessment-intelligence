SELECT
    da.assignment_label,
    da.assessment_window,
    ds.grade_level,
    ds.attendance_category,
    dc.course_track,
    COUNT(*) AS student_assignment_rows,
    SUM(CASE WHEN fas.is_present THEN 1 ELSE 0 END) AS present_rows,
    SUM(CASE WHEN fas.is_nonparticipation_zero THEN 1 ELSE 0 END) AS nonparticipation_zero_rows,
    ROUND(1 - AVG(CASE WHEN fas.is_present THEN 1.0 ELSE 0.0 END), 4) AS nonparticipation_rate,
    ROUND(AVG(fas.present_student_score), 2) AS avg_present_score
FROM mart.fact_assessment_score AS fas
JOIN mart.dim_student AS ds
    ON fas.student_dim_id = ds.student_dim_id
JOIN mart.dim_course AS dc
    ON fas.course_dim_id = dc.course_dim_id
JOIN mart.dim_assignment AS da
    ON fas.assignment_dim_id = da.assignment_dim_id
WHERE da.population_status = 'populated'
GROUP BY
    da.assignment_label,
    da.assessment_window,
    ds.grade_level,
    ds.attendance_category,
    dc.course_track
ORDER BY
    da.assignment_label,
    ds.grade_level,
    ds.attendance_category,
    dc.course_track;

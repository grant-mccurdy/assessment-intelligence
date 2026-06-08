SELECT
    dc.course_id,
    dc.course_name,
    dc.course_track,
    dsec.section_id,
    dsec.section_label,
    dt.teacher_id,
    dt.teacher_label,
    da.assignment_label,
    da.sequence_index,
    da.assessment_window,
    COUNT(*) AS enrolled_students,
    SUM(CASE WHEN fas.is_present THEN 1 ELSE 0 END) AS present_students,
    ROUND((1 - AVG(CASE WHEN fas.is_present THEN 1.0 ELSE 0.0 END))::numeric, 4) AS nonparticipation_rate,
    ROUND(AVG(fas.present_student_score)::numeric, 2) AS avg_present_score,
    ROUND(MIN(fas.present_student_score)::numeric, 2) AS min_present_score,
    ROUND(MAX(fas.present_student_score)::numeric, 2) AS max_present_score
FROM analytics.fact_assessment_score AS fas
JOIN analytics.dim_course AS dc
    ON fas.course_dim_id = dc.course_dim_id
JOIN analytics.dim_section AS dsec
    ON fas.section_dim_id = dsec.section_dim_id
JOIN analytics.dim_teacher AS dt
    ON fas.teacher_dim_id = dt.teacher_dim_id
JOIN analytics.dim_assignment AS da
    ON fas.assignment_dim_id = da.assignment_dim_id
WHERE da.population_status = 'populated'
GROUP BY
    dc.course_id,
    dc.course_name,
    dc.course_track,
    dsec.section_id,
    dsec.section_label,
    dt.teacher_id,
    dt.teacher_label,
    da.assignment_label,
    da.sequence_index,
    da.assessment_window
ORDER BY
    dc.course_id,
    dsec.section_id,
    da.sequence_index;

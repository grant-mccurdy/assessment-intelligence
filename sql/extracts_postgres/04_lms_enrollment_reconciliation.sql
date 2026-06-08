SELECT
    fle.source_system,
    fle.school_year,
    dc.course_id,
    dc.course_name,
    dc.course_track,
    dsec.section_id,
    dsec.section_label,
    dt.teacher_id,
    dt.teacher_label,
    fle.reconciliation_status,
    COUNT(*) AS enrollment_rows,
    SUM(CASE WHEN fle.is_active_enrollment THEN 1 ELSE 0 END) AS active_enrollments
FROM analytics.fact_lms_enrollment AS fle
JOIN analytics.dim_course AS dc
    ON fle.course_dim_id = dc.course_dim_id
JOIN analytics.dim_section AS dsec
    ON fle.section_dim_id = dsec.section_dim_id
JOIN analytics.dim_teacher AS dt
    ON fle.teacher_dim_id = dt.teacher_dim_id
GROUP BY
    fle.source_system,
    fle.school_year,
    dc.course_id,
    dc.course_name,
    dc.course_track,
    dsec.section_id,
    dsec.section_label,
    dt.teacher_id,
    dt.teacher_label,
    fle.reconciliation_status
ORDER BY
    dc.course_id,
    dsec.section_id,
    fle.reconciliation_status;

SELECT
    ds.student_dim_id,
    ds.sis_user_id,
    ds.student_label,
    ds.grade_level,
    ds.attendance_category,
    dc.course_id,
    dc.course_name,
    dc.course_track,
    dsec.section_id,
    dsec.section_label,
    dt.teacher_id,
    dt.teacher_label,
    sr.assignment_01_score,
    sr.assignment_02_score,
    sr.observed_growth_delta,
    sr.modeled_assignment_02_growth_delta,
    sr.posterior_readiness_after_assignment_02,
    sr.assignment_02_generation_mode,
    sr.academic_profile_status
FROM mart.student_readiness AS sr
JOIN mart.dim_student AS ds
    ON sr.sis_user_id = ds.sis_user_id
JOIN mart.dim_course AS dc
    ON sr.course_id = dc.course_id
JOIN mart.dim_section AS dsec
    ON sr.section_id = dsec.section_id
JOIN mart.dim_teacher AS dt
    ON sr.teacher_id = dt.teacher_id
ORDER BY
    ds.grade_level,
    dc.course_id,
    ds.sis_user_id;

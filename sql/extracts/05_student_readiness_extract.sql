SELECT
    ROW_NUMBER() OVER (ORDER BY school_year, sis_user_id) AS student_dim_id,
    sis_user_id,
    student_label,
    grade_level,
    attendance_category,
    course_id,
    course_name,
    course_track,
    section_id,
    section_label,
    teacher_id,
    teacher_label,
    boy_assignment_label,
    eoy_assignment_label,
    boy_score AS assignment_01_score,
    eoy_score AS assignment_02_score,
    observed_growth_delta,
    modeled_eoy_growth_delta AS modeled_assignment_02_growth_delta,
    posterior_readiness_after_eoy AS posterior_readiness_after_assignment_02,
    eoy_generation_mode AS assignment_02_generation_mode,
    academic_profile_status
FROM mart.student_readiness
ORDER BY
    grade_level,
    course_id,
    sis_user_id,
    boy_assignment_label;

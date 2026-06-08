SELECT
    student_dim_id,
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
    assignment_01_score,
    assignment_02_score,
    observed_growth_delta,
    modeled_assignment_02_growth_delta,
    posterior_readiness_after_assignment_02,
    assignment_02_generation_mode,
    academic_profile_status
FROM public.student_readiness_extract
ORDER BY
    grade_level,
    course_id,
    sis_user_id;

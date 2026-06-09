SELECT
    assignment_label,
    assessment_window,
    grade_level,
    attendance_category,
    course_track,
    COUNT(*) AS student_assignment_rows,
    SUM(CASE WHEN is_present THEN 1 ELSE 0 END) AS present_rows,
    SUM(CASE WHEN is_nonparticipation_zero THEN 1 ELSE 0 END) AS nonparticipation_zero_rows,
    ROUND(1 - AVG(CASE WHEN is_present THEN 1.0 ELSE 0.0 END), 4) AS nonparticipation_rate,
    ROUND(AVG(present_student_score), 2) AS avg_present_score
FROM mart.student_assessment_long
WHERE population_status = 'populated'
GROUP BY
    assignment_label,
    assessment_window,
    grade_level,
    attendance_category,
    course_track
ORDER BY
    assignment_label,
    grade_level,
    attendance_category,
    course_track;

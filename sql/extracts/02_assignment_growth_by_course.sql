WITH score_pairs AS (
    SELECT
        ds.student_dim_id,
        ds.grade_level,
        dc.course_id,
        dc.course_name,
        dc.course_track,
        MAX(CASE WHEN da.assignment_label = 'Assignment 01' AND fas.is_present THEN fas.score END) AS assignment_01_score,
        MAX(CASE WHEN da.assignment_label = 'Assignment 02' AND fas.is_present THEN fas.score END) AS assignment_02_score
    FROM mart.fact_assessment_score AS fas
    JOIN mart.dim_student AS ds
        ON fas.student_dim_id = ds.student_dim_id
    JOIN mart.dim_course AS dc
        ON fas.course_dim_id = dc.course_dim_id
    JOIN mart.dim_assignment AS da
        ON fas.assignment_dim_id = da.assignment_dim_id
    WHERE da.assignment_label IN ('Assignment 01', 'Assignment 02')
    GROUP BY
        ds.student_dim_id,
        ds.grade_level,
        dc.course_id,
        dc.course_name,
        dc.course_track
),
growth AS (
    SELECT
        *,
        assignment_02_score - assignment_01_score AS observed_growth_delta
    FROM score_pairs
    WHERE assignment_01_score IS NOT NULL
      AND assignment_02_score IS NOT NULL
)
SELECT
    grade_level,
    course_id,
    course_name,
    course_track,
    COUNT(*) AS matched_students,
    ROUND(AVG(assignment_01_score), 2) AS assignment_01_avg,
    ROUND(AVG(assignment_02_score), 2) AS assignment_02_avg,
    ROUND(AVG(observed_growth_delta), 2) AS avg_observed_growth_delta,
    ROUND(MIN(observed_growth_delta), 2) AS min_observed_growth_delta,
    ROUND(MAX(observed_growth_delta), 2) AS max_observed_growth_delta
FROM growth
GROUP BY
    grade_level,
    course_id,
    course_name,
    course_track
ORDER BY
    grade_level,
    course_id;

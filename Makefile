.PHONY: all r-check r-setup analytics-install synthetic-warehouse-extract sql-warehouse-report supabase-extract supabase-report ai-extract-review ai-extract-review-api toolchain-smoke toolchain-smoke-html toolchain-smoke-pdf toolchain-smoke-quarto assessment-pipeline gradebook-workflow gradebook-profile synthetic-gradebook validate-gradebook privacy-check memo render-report-html render-report-pdf render-gradebook-report-html render-gradebook-report-pdf clean-generated

PYTHON ?= python3
RSCRIPT ?= Rscript --vanilla
QUARTO ?= quarto
REFERENCE_GRADEBOOK ?=
SYNTHETIC_GRADEBOOK ?= data/synthetic/synthetic_gradebook.csv
SYNTHETIC_SCORES_LONG ?= data/synthetic/synthetic_student_scores_long.csv
SYNTHETIC_ASSIGNMENT_METADATA ?= data/synthetic/synthetic_assignment_metadata.csv
DASHBOARD_JSON ?= ../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json
SYNTHETIC_WAREHOUSE ?= ../synthetic-education-data/warehouse/synthetic_math.duckdb
SYNTHETIC_WAREHOUSE_EXTRACT_DIR ?= data/external/synthetic-education-data
SYNTHETIC_SUPABASE_EXTRACT_DIR ?= data/external/synthetic-education-data-supabase
SUPABASE_EXTRACT_REPORT ?= reports/supabase_assessment_extract.md
SUPABASE_ASSESSMENT_REPORT ?= reports/supabase_assessment_report.md
OPENAI_ENV_FILE ?= ../../.env

all: privacy-check

r-check:
	Rscript --version
	R --version
	pandoc --version
	quarto --version

r-setup:
	$(RSCRIPT) requirements.R

analytics-install:
	$(PYTHON) -m pip install -r requirements-analytics.txt || $(PYTHON) -m pip install --user --break-system-packages -r requirements-analytics.txt

synthetic-warehouse-extract:
	$(PYTHON) scripts/extract_synthetic_education_sql.py --warehouse "$(SYNTHETIC_WAREHOUSE)" --output-dir "$(SYNTHETIC_WAREHOUSE_EXTRACT_DIR)"

sql-warehouse-report: synthetic-warehouse-extract
	$(PYTHON) scripts/generate_sql_warehouse_assessment_report.py --extract-dir "$(SYNTHETIC_WAREHOUSE_EXTRACT_DIR)"

supabase-extract:
	$(PYTHON) scripts/extract_synthetic_education_sql.py --source supabase --output-dir "$(SYNTHETIC_SUPABASE_EXTRACT_DIR)" --report-path "$(SUPABASE_EXTRACT_REPORT)"

supabase-report: supabase-extract
	$(PYTHON) scripts/generate_sql_warehouse_assessment_report.py --extract-dir "$(SYNTHETIC_SUPABASE_EXTRACT_DIR)" --report "$(SUPABASE_ASSESSMENT_REPORT)"

ai-extract-review:
	$(PYTHON) scripts/generate_ai_extract_review.py --extract-dir "$(SYNTHETIC_SUPABASE_EXTRACT_DIR)" --extract-report "$(SUPABASE_EXTRACT_REPORT)" --analyst-report "$(SUPABASE_ASSESSMENT_REPORT)"

ai-extract-review-api:
	$(PYTHON) scripts/generate_ai_extract_review.py --extract-dir "$(SYNTHETIC_SUPABASE_EXTRACT_DIR)" --extract-report "$(SUPABASE_EXTRACT_REPORT)" --analyst-report "$(SUPABASE_ASSESSMENT_REPORT)" --env-file "$(OPENAI_ENV_FILE)" --call-api

toolchain-smoke: r-check toolchain-smoke-html toolchain-smoke-pdf toolchain-smoke-quarto

toolchain-smoke-html:
	$(RSCRIPT) -e "rmarkdown::render('reports/r_toolchain_smoke_test.Rmd', output_format='html_document', output_file='r_toolchain_smoke_test.html')"

toolchain-smoke-pdf:
	$(RSCRIPT) -e "rmarkdown::render('reports/r_toolchain_smoke_test.Rmd', output_format='pdf_document', output_file='r_toolchain_smoke_test.pdf')"

toolchain-smoke-quarto:
	ORIGINAL_HOME=$$HOME; HOME=$${QUARTO_HOME:-/tmp} R_LIBS_USER=$${R_LIBS_USER:-$${ORIGINAL_HOME}/R/x86_64-pc-linux-gnu-library/4.3} R_PROFILE_USER=/dev/null R_ENVIRON_USER=/dev/null $(QUARTO) render reports/quarto_toolchain_smoke_test.qmd --to html

assessment-pipeline:
	$(RSCRIPT) analysis/run_pipeline.R

gradebook-workflow: gradebook-profile synthetic-gradebook validate-gradebook

check-reference:
	@if [ -z "$(REFERENCE_GRADEBOOK)" ]; then \
		echo "Set REFERENCE_GRADEBOOK to a private gradebook path."; \
		exit 1; \
	fi

gradebook-profile: check-reference
	$(RSCRIPT) analysis/profile_reference_schema.R --reference-gradebook "$(REFERENCE_GRADEBOOK)"

synthetic-gradebook: check-reference
	$(RSCRIPT) analysis/generate_synthetic_gradebook.R --reference-gradebook "$(REFERENCE_GRADEBOOK)" --output "$(SYNTHETIC_GRADEBOOK)" --analytics-output "$(SYNTHETIC_SCORES_LONG)" --metadata-output "$(SYNTHETIC_ASSIGNMENT_METADATA)"

validate-gradebook: check-reference
	$(RSCRIPT) analysis/validate_synthetic_gradebook.R --reference-gradebook "$(REFERENCE_GRADEBOOK)" --synthetic-gradebook "$(SYNTHETIC_GRADEBOOK)" --analytics-output "$(SYNTHETIC_SCORES_LONG)" --metadata-output "$(SYNTHETIC_ASSIGNMENT_METADATA)"

privacy-check:
	$(PYTHON) scripts/validate_synthetic_privacy.py --input "$(DASHBOARD_JSON)"

memo:
	$(PYTHON) scripts/generate_ai_assessment_memo.py --input "$(DASHBOARD_JSON)"

render-report-html:
	$(RSCRIPT) -e "rmarkdown::render('reports/assessment_modeling_report.Rmd', output_format='html_document', knit_root_dir=getwd())"

render-report-pdf:
	$(RSCRIPT) -e "rmarkdown::render('reports/assessment_modeling_report.Rmd', output_format='pdf_document', knit_root_dir=getwd())"

render-gradebook-report-html:
	$(RSCRIPT) -e "rmarkdown::render('reports/gradebook_synthesis_report.Rmd', output_format='html_document', knit_root_dir=getwd())"

render-gradebook-report-pdf:
	$(RSCRIPT) -e "rmarkdown::render('reports/gradebook_synthesis_report.Rmd', output_format='pdf_document', knit_root_dir=getwd())"

clean-generated:
	$(PYTHON) scripts/clean_public_generated.py

CRED_ENV_FILE=creds.env
MLFLOW_ENV_FILE=infra/mlflow/.env
TEMPLATES=infra/postgres/.env.template infra/mlflow/.env.template infra/MinIO/.env.template creds.env.template
DEST_DIR=infra

# Load variables from credentials environment file, if it exists
ifneq ("$(wildcard $(CRED_ENV_FILE))","")
include $(CRED_ENV_FILE)
export $(shell awk -F= '{print $$1}' $(CRED_ENV_FILE))
endif

# Creates the environmental files from templates, starts
# MinIO and dev-container to create mounted directories.
init:
	@echo "Initializing environment..."
	@for file in $(TEMPLATES); do \
		dest=$$(echo $$file | sed 's/\.template$$//'); \
		cp $$file $$dest && echo "Created $$dest from $$file"; \
	done
	@echo "Starting Docker Compose services..."
	cd infra && docker compose up minio dev-container

# Copies template files from the source repository to the specified directory.
newproject:
	@echo "Cloning template repository next to the existing project directory..."
	@cd infra/workspace && git clone $(TEMPLATE_REPO)
	@cd infra/workspace/$(REPO_NAME) && git checkout -b template
	@rsync -av --exclude '.git' --exclude 'README.md' infra/workspace/DS_template/ infra/workspace/$(REPO_NAME)/
	@cd infra/workspace/$(REPO_NAME) && git add .
	@echo "Cleaning up temporary files..."
	@rm -rf infra/workspace/DS_template/
	@echo "Project $(REPO_NAME) updated successfully with template files."

# Creating virtual environment and install dependencies in dev-container
# via running `make install` command.
install:
	docker exec -it --user 1000:1000 $(DEV_CONTAINER) bash -c "\
		cd /workspace/$(REPO_NAME) && \
		make install"

# Initialize DVC in the specified directory.
# Then adds the S3 bucket to the DVC repository.
adddvc:
	docker exec -it --user 1000:1000 $(DEV_CONTAINER) bash -c "\
		cd /workspace/$(REPO_NAME) && \
		git branch dvc && \
		git checkout dvc && \
		source .venv/bin/activate && \
		dvc init && \
		dvc remote add -d my_s3_bucket s3://$(MINIO_BUCKET_NAME) && \
		dvc remote modify my_s3_bucket use_ssl false && \
		dvc remote modify my_s3_bucket endpointurl http://minio:9000 && \
		dvc remote modify --local my_s3_bucket access_key_id $(MINIO_ACCESS_KEY) && \
		dvc remote modify --local my_s3_bucket secret_access_key $(MINIO_SECRET_KEY) && \
		git add .dvc/config && \
		dvc add data && \
		git add data.dvc && \
		echo 'S3 bucket successfully connected, DVC initialized.' && \
		echo 'We recommend running the following commands to create the first data tracking record:' && \
		echo '  dvc commit' && \
		echo '  git commit'"

# Edits the credentials in the credentials environment file.
addcreds:
	@echo "Editing credentials in $(CRED_ENV_FILE)..."
	@for var in "MINIO_BUCKET_NAME:MinIO bucket name" \
				"MINIO_ACCESS_KEY:MinIO access key" \
				"MINIO_SECRET_KEY:MinIO secret key" \
				"REPO_NAME:Repository name" \
				"DEV_CONTAINER:Dev container name"; do \
		key=$$(echo $$var | cut -d':' -f1); \
		desc=$$(echo $$var | cut -d':' -f2); \
		current_value=$$(grep "^$$key=" $(CRED_ENV_FILE) | cut -d'=' -f2 || echo ""); \
		echo "Current $$desc: $$current_value"; \
		printf "Enter new $$desc (leave empty to keep current): "; \
		read value; \
		if [ -n "$$value" ]; then \
			if grep -q "^$$key=" $(CRED_ENV_FILE); then \
				sed -i "s/^$$key=.*/$$key=$$value/" $(CRED_ENV_FILE); \
				echo "Updated $$key in $(CRED_ENV_FILE)"; \
			else \
				echo "$$key=$$value" >> $(CRED_ENV_FILE); \
				echo "Added $$key to $(CRED_ENV_FILE)"; \
			fi; \
		else \
			echo "Kept current $$key"; \
		fi; \
	done

	@echo "Overwriting S3 keys in $(MLFLOW_ENV_FILE)..."
	@S3_ACCESS_KEY_ID=$$(grep "^MINIO_ACCESS_KEY=" $(CRED_ENV_FILE) | cut -d'=' -f2); \
	S3_SECRET_ACCESS_KEY=$$(grep "^MINIO_SECRET_KEY=" $(CRED_ENV_FILE) | cut -d'=' -f2); \
	echo "S3_ACCESS_KEY_ID=$$S3_ACCESS_KEY_ID" > $(MLFLOW_ENV_FILE); \
	echo "S3_SECRET_ACCESS_KEY=$$S3_SECRET_ACCESS_KEY" >> $(MLFLOW_ENV_FILE); \
	echo "S3 keys overwritten in $(MLFLOW_ENV_FILE)."

# Set the git safe directory to the project directory
# Fixing dubious ownership issues
fixgit:
	@docker exec -it --user 1000:1000 $(DEV_CONTAINER) bash -c "\
		git config --global --add safe.directory /workspace/$(REPO_NAME)"
	@echo "Git safe directory set to /workspace/$(REPO_NAME)"
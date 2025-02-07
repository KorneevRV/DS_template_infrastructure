CRED_ENV_FILE=creds.env
MLFLOW_ENV_FILE=src/mlflow/.env
TEMPLATES=src/postgres/.env.template src/mlflow/.env.template src/MinIO/.env.template creds.env.template

# Load variables from credentials environment file, if it exists
ifneq ("$(wildcard $(CRED_ENV_FILE))","")
include $(CRED_ENV_FILE)
export $(shell awk -F= '{print $$1}' $(CRED_ENV_FILE))
endif

# Creates the environmental files from templates
env:
	@echo "Initializing environment..."; \
	for file in $(TEMPLATES); do \
		dest=$$(echo $$file | sed 's/\.template$$//'); \
		cp $$file $$dest && echo "Created $$dest from $$file"; \
	done; \
	echo "Environment initialized successfully."

# Starts all containers
start:
	@echo "Starting Docker Compose services..."
	docker compose -f src/docker-compose.yml up -d

# Edits the credentials in the credentials environment file.
# Overwrites MinIO keys in MLFlow environment file.
addcreds:
	@echo "Editing credentials in $(CRED_ENV_FILE)..."
	@for var in "MINIO_ACCESS_KEY:MinIO access key" \
				"MINIO_SECRET_KEY:MinIO secret key"; do \
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
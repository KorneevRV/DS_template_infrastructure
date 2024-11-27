include creds.env
export $(shell sed 's/=.*//' creds.env)

# Copies template files from the source repository to the specified directory.
newproject:
	cd infra/workspace/$(REPO_NAME) && \
	git remote add template $(TEMPLATE_REPO) && \
	git fetch --depth 1 template main && \
	git checkout -b template && \
	git checkout template/main -- . ':!README.md' && \
	git add . && \
	git commit -m "Merge DS project template" && \
	git remote remove template

# Initialize DVC in the specified directory.
# Then adds the S3 bucket to the DVC repository.
adds3:
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
		git rm -r --cached 'data' && \
		git commit -m 'stop tracking data' && \
		dvc add data && \
		git add data.dvc && \
		echo 'S3 bucket successfully connected, DVC initialized.' && \
		echo 'We recommend running the following commands to create the first data tracking record:' && \
		echo '  dvc commit' && \
		echo '  git commit'"

SOURCE_REPO = https://github.com/KorneevRV/DS_template

# Copies template files from the source repository to the specified directory.
# Requires the DIR variable to be set (e.g., make newproject DIR=/path/to/target_repo).
newproject:
	cd $(DIR) && \
	git remote add source $(SOURCE_REPO) && \
	git fetch --depth 1 source main && \
	git checkout source/main -- . ':!README.md' && \
	git add . && \
	git commit -m "Merge DS project template" && \
	git remote remove source

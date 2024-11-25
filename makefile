PYTHON = python3
VENV = .venv

# creating virtual environment
venv:
	$(PYTHON) -m venv $(VENV)
	@echo "Virtual environment created in '$(VENV)'"

# installing packages
install: venv
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r requirements.txt
	@echo "Dependencies installed in the virtual environment"

# cleaning temporary files
clean:
	find . -name "__pycache__" -exec rm -rf {} +
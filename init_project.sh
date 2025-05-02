#!/bin/bash

# Usage function
usage() {
  echo "Usage: $0 app_name model1:field1,field2 [model2:field1,field2,field3 ...]"
  echo "Example: $0 api product:name,price,description user:username,email,password"
  exit 1
}

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
  usage
fi

# Set project name and extract app name
PROJECT_DIR="Angular-Init-Automation"
APP_NAME="$1"
shift

# Process models and their fields
MODELS_DATA=""
for model_arg in "$@"; do
  # Split by colon to separate model name and fields
  IFS=':' read -r model_name fields <<< "$model_arg"
  if [ -z "$model_name" ] || [ -z "$fields" ]; then
    echo "Error: Invalid model format. Use model_name:field1,field2,..."
    usage
  fi
  
  # Add to MODELS_DATA with a semicolon separator between models
  if [ -z "$MODELS_DATA" ]; then
    MODELS_DATA="${model_name}:${fields}"
  else
    MODELS_DATA="${MODELS_DATA};${model_name}:${fields}"
  fi
done

# Step 1: Clone the repository if not exists
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Cloning Angular project template..."
  git clone https://github.com/ahmedhamila/Angular-Init-Automation.git
fi

# Step 2: Navigate into project
cd $PROJECT_DIR

# Step 3: Make sure the scripts directory exists
mkdir -p scripts

# Step 4: Create or update .env file
echo "Creating .env file..."
cat > .env << EOF
APP_NAME=$APP_NAME
MODELS_DATA="$MODELS_DATA"
EOF

# Step 5: Start Docker Compose
echo "Starting Docker containers..."
docker-compose up -d --build

echo "Angular app with CRUD for models is being created..."
echo "Access your project at http://localhost:4200"
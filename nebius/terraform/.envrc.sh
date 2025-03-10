#!/bin/bash

PRODUCT="vm"


unset NEBIUS_IAM_TOKEN
export NEBIUS_IAM_TOKEN=$(nebius iam get-access-token)
export TF_VAR_iam_token=$NEBIUS_IAM_TOKEN

# File to store the last selected project
LAST_SELECTED_TENANT_FILE=".last_selected_tenant"
LAST_SELECTED_PROJECT_FILE=".last_selected_project"

# Check if necessary tools are installed
REQUIRED_TOOLS=("fzf" "jq")
INSTALL_COMMAND=""

# Determine the package manager
if command -v apt &>/dev/null; then
    INSTALL_COMMAND="sudo apt install -y"
elif command -v yum &>/dev/null; then
    INSTALL_COMMAND="sudo yum install -y"
elif command -v dnf &>/dev/null; then
    INSTALL_COMMAND="sudo dnf install -y"
elif command -v brew &>/dev/null; then
    INSTALL_COMMAND="brew install"
else
    echo "Unsupported package manager. Please install required tools manually: ${REQUIRED_TOOLS[*]}"
    return 1
fi

# Check and install missing tools
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo "$tool is not installed. Installing..."
        $INSTALL_COMMAND "$tool"
        if [[ $? -ne 0 ]]; then
            echo "Failed to install $tool. Please install it manually."
            return 1
        fi
    fi
done

# Fetch the data from the command
OUTPUT=$(nebius iam tenant list --page-size 100 --format json)

# Parse the names and IDs from the output
declare -A TENANTS
while IFS= read -r line; do
    # Extract tenant names and IDs
    name=$(echo "$line" | jq -r '.metadata.name')
    id=$(echo "$line" | jq -r '.metadata.id')
    [[ -n "$name" && -n "$id" ]] && TENANTS["$name"]=$id
done < <(echo "$OUTPUT" | jq -c '.items[]')

# Check if tenant list is empty
if [[ ${#TENANTS[@]} -eq 0 ]]; then
    echo "No tenants found. Exiting."
    return 0
fi

# Create a list with both names and IDs
tenant_list=$(for name in "${!TENANTS[@]}"; do
    echo "$name (${TENANTS[$name]})"
done)

# Prepend the last selected tenant to the list, if it exists
if [[ -f "$LAST_SELECTED_TENANT_FILE" ]]; then
    last_selected=$(<"$LAST_SELECTED_TENANT_FILE")
    tenant_list=$(echo "$last_selected"; echo "$tenant_list" | grep -v -F "$last_selected")
fi

# Use fzf for selection
selected=$(echo "$tenant_list" | fzf --prompt="Select a tenant: " --height=20 --reverse --exact --header="Arrow keys to navigate, Enter to select")

# Check if the selection is empty
if [[ -z "$selected" ]]; then
    echo "No tenant selected."
    return 0
fi

# Extract the selected name and ID safely
tenant_name=$(echo "$selected" | sed -E 's/^(.*)[[:space:]]\(.*/\1/')
tenant_id=$(echo "$selected" | sed -E 's/^.*\((.*)\)$/\1/')

# Save the selection for the next run
echo "$selected" > "$LAST_SELECTED_TENANT_FILE"
# Fetch the data from the command

# Now, execute the command
OUTPUT=$(nebius iam project list --page-size 100 --parent-id "$tenant_id" --format json)

declare -A PROJECTS
while IFS= read -r line; do
    # Extract tenant names and IDs
    name=$(echo "$line" | jq -r '.metadata.name')
    id=$(echo "$line" | jq -r '.metadata.id')
    [[ -n "$name" && -n "$id" ]] && PROJECTS["$name"]=$id
done < <(echo "$OUTPUT" | jq -c '.items[]')

# Check if project list is empty
if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    echo "No projects found. Exiting."
    return 0
fi


# Create a list with both names and IDs
project_list=$(for name in "${!PROJECTS[@]}"; do
    echo "$name (${PROJECTS[$name]})"
done)

# Prepend the last selected project to the list, if it exists
if [[ -f "$LAST_SELECTED_PROJECT_FILE" ]]; then
    last_selected=$(<"$LAST_SELECTED_PROJECT_FILE")
    echo "LAST SELECTION: $last_selected"
    # Check if the last selected item exists in the current tenant list
    if echo "$project_list" | grep -q -F "$last_selected"; then
        project_list=$(echo "$last_selected"; echo "$project_list" | grep -v -F "$last_selected")
    fi
fi

# Use fzf for selection
selected=$(echo "$project_list" | fzf --prompt="Select a project: " --height=20 --reverse --exact --header="Arrow keys to navigate, Enter to select")

# Check if the selection is empty
if [[ -z "$selected" ]]; then
    echo "No project selected."
    return 0
fi

# Extract the selected name and ID safely
project_name=$(echo "$selected" | sed -E 's/^(.*)[[:space:]]\(.*/\1/')
project_id=$(echo "$selected" | sed -E 's/^.*\((.*)\)$/\1/')
unset TENANTS
unset PROJECTS

# Save the selection for the next run
echo "$selected" > "$LAST_SELECTED_PROJECT_FILE"

export NEBIUS_TENANT_ID=$tenant_id
export NEBIUS_PROJECT_ID=$project_id
# Output the result
echo "Selected tenant: $tenant_name ($tenant_id)"
echo "Selected project: $project_name ($project_id)"


if [ "$1" == "destroy" ]; then
  NEBIUS_BUCKET_NAME="tfstate-${PRODUCT}-$(echo -n "${NEBIUS_TENANT_ID}-${NEBIUS_PROJECT_ID}" | md5sum | awk '$0=$1')"

  read -p "Are you sure you want to destroy ${NEBIUS_BUCKET_NAME}? Type 'yes' to confirm: " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "Aborting."
    return 1
  fi

  BUCKET_ID=$(nebius storage bucket get-by-name --name ${NEBIUS_BUCKET_NAME} --format json | jq -r '.metadata.id')
  echo ${BUCKET_ID}
  nebius storage bucket delete --id ${BUCKET_ID} --ttl 0
  return 0
fi


# region VPC subnet
NEBIUS_VPC_SUBNET_ID=$(nebius vpc subnet list \
  --parent-id "${NEBIUS_PROJECT_ID}" \
  --format json \
  | jq -r '.items[0].metadata.id')
export NEBIUS_VPC_SUBNET_ID

# endregion VPC subnet

# Export Terraform variables
export TF_VAR_iam_token="${NEBIUS_IAM_TOKEN}"
export TF_VAR_iam_tenant_id="${NEBIUS_TENANT_ID}"
export TF_VAR_iam_project_id="${NEBIUS_PROJECT_ID}"
export TF_VAR_vpc_subnet_id="${NEBIUS_VPC_SUBNET_ID}"

echo "Exported variables:"
echo "TF_VAR_iam_token: sensitive"
echo "NEBIUS_TENANT_ID, TF_VAR_iam_tenant_id: ${NEBIUS_TENANT_ID}"
echo "NEBIUS_PROJECT_ID, TF_VAR_iam_project_id: ${NEBIUS_PROJECT_ID}"
echo "NEBIUS_VPC_SUBNET_ID, TF_VAR_vpc_subnet_id: ${NEBIUS_VPC_SUBNET_ID}"

# endregion TF variables
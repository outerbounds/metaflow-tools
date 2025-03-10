#!/bin/zsh
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
if (( $+commands[apt] )); then
    INSTALL_COMMAND="sudo apt install -y"
elif (( $+commands[yum] )); then
    INSTALL_COMMAND="sudo yum install -y"
elif (( $+commands[dnf] )); then
    INSTALL_COMMAND="sudo dnf install -y"
elif (( $+commands[brew] )); then
    INSTALL_COMMAND="brew install"
else
    echo "Unsupported package manager. Please install required tools manually: ${REQUIRED_TOOLS[*]}"
    return 1
fi

# Check and install missing tools
for tool in "${REQUIRED_TOOLS[@]}"; do
    if (( ! $+commands[$tool] )); then
        echo "$tool is not installed. Installing..."
        $INSTALL_COMMAND "$tool"
        if [[ $? -ne 0 ]]; then
            echo "Failed to install $tool. Please install it manually."
            return 1
        fi
    fi
done

# Ensure TENANTS is declared as an associative array in Zsh
typeset -A TENANTS

# Fetch the tenant list
OUTPUT=$(nebius iam tenant list --page-size 100 --format json)

# Parse the names and IDs from JSON output
while IFS= read -r line; do
    name=$(echo "$line" | jq -r '.metadata.name')
    id=$(echo "$line" | jq -r '.metadata.id')
    [[ -n "$name" && -n "$id" ]] && TENANTS[$name]=$id
done < <(echo "$OUTPUT" | jq -c '.items[]')

# Check if tenants are available
if [[ ${#TENANTS[@]} -eq 0 ]]; then
    echo "No tenants found. Exiting."
    return 1
fi

# Create the selection list (proper multi-line output)
tenant_list=()
for name in "${(@k)TENANTS}"; do
    tenant_list+=("$name (${TENANTS[$name]})")
done

# Load last selection if available
if [[ -f "$LAST_SELECTED_TENANT_FILE" ]]; then
    last_selected=$(<"$LAST_SELECTED_TENANT_FILE")
    if [[ -n "$last_selected" ]]; then
        tenant_list=("$last_selected" "${(@)tenant_list:#$last_selected}")
    fi
fi

# Ensure tenant list prints each item on a new line
selected=$(printf "%s\n" "${tenant_list[@]}" | fzf --prompt="Select a tenant: " --height=20 --reverse --exact --header="Arrow keys to navigate, Enter to select")

# Validate selection
if [[ -z "$selected" ]]; then
    echo "No tenant selected."
    return 1
fi

# Extract selected tenant name and ID
tenant_name=$(echo "$selected" | sed -E 's/^(.*)[[:space:]]\(.*/\1/')
tenant_id=$(echo "$selected" | sed -E 's/^.*\((.*)\)$/\1/')

# Save the selection
echo "$selected" > "$LAST_SELECTED_TENANT_FILE"

# Export variables
export NEBIUS_TENANT_ID="$tenant_id"
echo "Selected tenant: $tenant_name ($tenant_id)"

# Save the selection for the next run
echo "$selected" > "$LAST_SELECTED_TENANT_FILE"

# Fetch projects
# Fetch the data for projects
OUTPUT=$(nebius iam project list --page-size 100 --parent-id "$tenant_id" --format json)

# Declare the PROJECTS associative array
typeset -A PROJECTS

# Parse the names and IDs from the output
while IFS= read -r line; do
    name=$(echo "$line" | jq -r '.metadata.name')
    id=$(echo "$line" | jq -r '.metadata.id')
    [[ -n "$name" && -n "$id" ]] && PROJECTS[$name]=$id
done < <(echo "$OUTPUT" | jq -c '.items[]')

# Check if project list is empty
if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    echo "No projects found. Exiting."
    return 1
fi

# Create the project list (proper multi-line output)
project_list=()
for name in "${(@k)PROJECTS}"; do
    project_list+=("$name (${PROJECTS[$name]})")
done

# Prepend the last selected project to the list, if it exists
if [[ -f "$LAST_SELECTED_PROJECT_FILE" ]]; then
    last_selected=$(<"$LAST_SELECTED_PROJECT_FILE")
    echo "LAST SELECTION: $last_selected"
    # Check if the last selected project exists in the current list
    if echo "$project_list" | grep -q -F "$last_selected"; then
        project_list=("$last_selected" "${(@)project_list:#$last_selected}")
    fi
fi

# Use fzf to select the project
selected=$(printf "%s\n" "${project_list[@]}" | fzf --prompt="Select a project: " --height=20 --reverse --exact --header="Arrow keys to navigate, Enter to select")

# Check if the selection is empty
if [[ -z "$selected" ]]; then
    echo "No project selected."
    return 1
fi

# Extract the selected project name and ID
project_name=$(echo "$selected" | sed -E 's/^(.*)[[:space:]]\(.*/\1/')
project_id=$(echo "$selected" | sed -E 's/^.*\((.*)\)$/\1/')

# Save the selection for the next run
echo "$selected" > "$LAST_SELECTED_PROJECT_FILE"

# Export variables
export NEBIUS_PROJECT_ID="$project_id"
echo "Selected project: $project_name ($project_id)"

export NEBIUS_TENANT_ID=$tenant_id
export NEBIUS_PROJECT_ID=$project_id

if [[ "$1" == "destroy" ]]; then
  NEBIUS_BUCKET_NAME="tfstate-${PRODUCT}-$(echo -n "${NEBIUS_TENANT_ID}-${NEBIUS_PROJECT_ID}" | md5sum | awk '$0=$1')"

  # Using Zsh's read prompt
  read "?Are you sure you want to destroy ${NEBIUS_BUCKET_NAME}? Type 'yes' to confirm: " CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborting."
    return 1
  fi

  # Fetch the bucket ID using the given bucket name
  BUCKET_ID=$(nebius storage bucket get-by-name --name "${NEBIUS_BUCKET_NAME}" --format json | jq -r '.metadata.id')
  echo "${BUCKET_ID}"

  # Delete the bucket with the fetched ID
  nebius storage bucket delete --id "${BUCKET_ID}" --ttl 0
  return 0
fi

# VPC subnet
NEBIUS_VPC_SUBNET_ID=$(nebius vpc subnet list \
  --parent-id "${NEBIUS_PROJECT_ID}" \
  --format json \
  | jq -r '.items[0].metadata.id')
export NEBIUS_VPC_SUBNET_ID

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
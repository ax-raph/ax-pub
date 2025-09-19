#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF
Usage:
  $0 --subs "subId1 subId2" [--name APP_NAME] [--years N]
  $0 --mg MG_ID [--name APP_NAME] [--years N]
  $0 --check --subs "subId1 [subId2]"|--mg MG_ID

Options:
  --subs     One or more Azure subscription IDs (space-separated).
  --mg       One management group ID.
  --name     Name of the Azure AD app registration (default: Axonius-Azure-Adapter).
  --years    Validity of the client secret in years (default: 2). Optional.
  --check    Only check if the current user has the required permissions at the specified scope(s).
  --help     Show this help.

Notes:
  - Creating the App Registration can succeed even if you CANNOT assign RBAC.
    To assign the Reader role, you must have **Owner** OR **User Access Administrator** at the target scope.

Examples:
  $0 --subs "00000000-0000-0000-0000-000000000000"
  $0 --subs "sub1 sub2 sub3" --name MyAxoniusApp --years 3
  $0 --mg my-mg-id
  $0 --check --subs "00000000-0000-0000-0000-000000000000"
EOF
}

APP_NAME="Axonius-Azure-Adapter"
SECRET_YEARS=2
SUBSCRIPTION_IDS=""
MG_ID=""
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --subs) SUBSCRIPTION_IDS="$2"; shift 2 ;;
    --mg)   MG_ID="$2"; shift 2 ;;
    --name) APP_NAME="$2"; shift 2 ;;
    --years) SECRET_YEARS="$2"; shift 2 ;;
    --check) CHECK_ONLY=true; shift 1 ;;
    --help) show_help; exit 0 ;;
    *) echo "Error: Unknown arg: $1"; show_help; exit 1 ;;
  esac
done

# Ensure logged in
az account show >/dev/null || az login >/dev/null

# Helper: check RBAC at a scope (needs Owner or User Access Administrator)
has_rbac_rights() {
  local scope="$1"
  local uid
  uid=$(az ad signed-in-user show --query id -o tsv)
  # include inherited assignments at this scope
  local roles
  roles=$(az role assignment list \
    --assignee "$uid" \
    --scope "$scope" \
    --include-inherited \
    --query "[].roleDefinitionName" -o tsv || true)
  if echo "$roles" | grep -q "Owner"; then return 0; fi
  if echo "$roles" | grep -q "User Access Administrator"; then return 0; fi
  return 1
}

# If we're only checking, validate scopes and report RBAC capability
if [[ "$CHECK_ONLY" == true ]]; then
  if [[ -z "$MG_ID" && -z "${SUBSCRIPTION_IDS// /}" ]]; then
    echo "Error: --check requires you to specify --subs or --mg so the scope can be validated." >&2
    exit 1
  fi
  rc=0
  if [[ -n "${SUBSCRIPTION_IDS// /}" ]]; then
    for sub in $SUBSCRIPTION_IDS; do
      scope="/subscriptions/${sub}"
      if has_rbac_rights "$scope"; then
        echo "OK: You have RBAC to assign roles at $scope (Owner or User Access Administrator)."
      else
        echo "FAIL: Missing RBAC to assign roles at $scope. Required: Owner or User Access Administrator." >&2
        rc=1
      fi
    done
  fi
  if [[ -n "$MG_ID" ]]; then
    scope="/providers/Microsoft.Management/managementGroups/${MG_ID}"
    if has_rbac_rights "$scope"; then
      echo "OK: You have RBAC to assign roles at $scope (Owner or User Access Administrator)."
    else
      echo "FAIL: Missing RBAC to assign roles at $scope. Required: Owner or User Access Administrator." >&2
      rc=1
    fi
  fi
  exit $rc
fi

# Validation for create path
if [[ -n "$MG_ID" && -n "${SUBSCRIPTION_IDS// /}" ]]; then
  echo "Error: Specify EITHER subscriptions OR a management group, not both." >&2
  exit 1
fi
if [[ -z "$MG_ID" && -z "${SUBSCRIPTION_IDS// /}" ]]; then
  echo "Error: Must specify subscriptions or a management group." >&2
  exit 1
fi

# Before creating, verify we can assign Reader at the chosen scope(s)
if [[ -n "${SUBSCRIPTION_IDS// /}" ]]; then
  for sub in $SUBSCRIPTION_IDS; do
    scope="/subscriptions/${sub}"
    if ! has_rbac_rights "$scope"; then
      echo "Error: You do not have sufficient RBAC to assign roles at $scope. Required: Owner or User Access Administrator." >&2
      exit 1
    fi
  done
fi
if [[ -n "$MG_ID" ]]; then
  scope="/providers/Microsoft.Management/managementGroups/${MG_ID}"
  if ! has_rbac_rights "$scope"; then
    echo "Error: You do not have sufficient RBAC to assign roles at $scope. Required: Owner or User Access Administrator." >&2
    exit 1
  fi
fi

# Create app reg
echo "Creating AAD app registration: $APP_NAME"
appId=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)

# Create service principal
echo "Creating service principal"
az ad sp create --id "$appId" >/dev/null

# Create client secret
echo "Creating client secret"
clientSecret=$(az ad app credential reset --id "$appId" --append --years "$SECRET_YEARS" --query password -o tsv)

tenantId=$(az account show --query tenantId -o tsv)

assignedScope=""
if [[ -n "${SUBSCRIPTION_IDS// /}" ]]; then
  for sub in $SUBSCRIPTION_IDS; do
    scope="/subscriptions/${sub}"
    echo "Assigning Reader on: $scope"
    az role assignment create --assignee "$appId" --role "Reader" --scope "$scope" >/dev/null
    assignedScope=$scope
  done
elif [[ -n "$MG_ID" ]]; then
  scope="/providers/Microsoft.Management/managementGroups/${MG_ID}"
  echo "Assigning Reader on: $scope"
  az role assignment create --assignee "$appId" --role "Reader" --scope "$scope" >/dev/null
  assignedScope=$scope
fi

echo
jq -n --arg clientId "$appId" \
      --arg tenantId "$tenantId" \
      --arg clientSecret "$clientSecret" \
      --arg scope "$assignedScope" \
      '{clientId:$clientId, tenantId:$tenantId, clientSecret:$clientSecret, scope:$scope}'

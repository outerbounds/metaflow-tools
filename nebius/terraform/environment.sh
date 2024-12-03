#!/bin/sh
unset NEBIUS_IAM_TOKEN
token="$(nebius iam get-access-token)"
export NEBIUS_IAM_TOKEN="$token"
export TF_VAR_iam_token="$token"
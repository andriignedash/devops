#!/usr/bin/env bash
set -e
export AWS_PROFILE="${AWS_PROFILE:-final}"
export AWS_REGION="${AWS_REGION:-eu-central-1}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-central-1}"
aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION"

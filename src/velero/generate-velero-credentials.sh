#!/bin/bash

# instructions come from:
# https://github.com/vmware-tanzu/velero-plugin-for-aws

if [[ "${K8S_EXP_ENVIRONMENT}" == "" ]]; then
  echo "Error: K8S_EXP_ENVIRONMENT not set"
  exit 1
fi
if [[ "${K8S_EXP_VELERO_S3_BUCKET}" == "" ]]; then
  echo "Error: K8S_EXP_VELERO_S3_BUCKET not set"
  exit 1
fi

aws iam create-user --user-name velero-${K8S_EXP_CLUSTER_NAME}
cat > velero-policy-${K8S_EXP_CLUSTER_NAME}.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${K8S_EXP_VELERO_S3_BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${K8S_EXP_VELERO_S3_BUCKET}"
            ]
        }
    ]
}
EOF
aws iam put-user-policy \
  --user-name velero-${K8S_EXP_CLUSTER_NAME} \
  --policy-name velero-${K8S_EXP_CLUSTER_NAME} \
  --policy-document file://velero-policy-${K8S_EXP_CLUSTER_NAME}.json
json_output=$(aws iam create-access-key --user-name velero-${K8S_EXP_CLUSTER_NAME})

# example json_output looks like this:
# {
#     "AccessKey": {
#         "UserName": "velero-testing",
#         "AccessKeyId": "this-is-a-secret",
#         "Status": "Active",
#         "SecretAccessKey": "this-is-another-secret",
#         "CreateDate": "2020-06-03T10:22:46+00:00"
#     }
# }

VELERO_ACCESS_KEY_ID=$(echo "$json_output" | jq -r ".AccessKey.AccessKeyId")
VELERO_SECRET_ACCESS_KEY=$(echo "$json_output" | jq -r ".AccessKey.SecretAccessKey")
echo "VELERO_ACCESS_KEY_ID: ${VELERO_ACCESS_KEY_ID}"
echo "VELERO_SECRET_ACCESS_KEY: ${VELERO_SECRET_ACCESS_KEY}"
cat > credentials-velero.json <<EOF
[default]
aws_access_key_id=${VELERO_ACCESS_KEY_ID}
aws_secret_access_key=${VELERO_SECRET_ACCESS_KEY}
EOF
echo "Credentials file created: ${PWD}/credentials-velero.json"

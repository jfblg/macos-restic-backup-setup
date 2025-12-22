#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

echo "This script will help you setup an AWS IAM user and S3 bucket for Restic."
echo "Ensure you have configured your AWS CLI with administrative credentials (aws configure)."
echo ""

read -p "Enter the desired S3 Bucket Name: " BUCKET_NAME
read -p "Enter the desired IAM User Name (e.g., restic-backup-user): " IAM_USER_NAME

if [ -z "$BUCKET_NAME" ] || [ -z "$IAM_USER_NAME" ]; then
    echo "Error: Bucket Name and IAM User Name are required."
    exit 1
fi

# Create Bucket (if it doesn't exist)
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket '$BUCKET_NAME' already exists."
else
    echo "Creating bucket '$BUCKET_NAME'..."
    # Note: Location constraint might be needed depending on region, default is us-east-1
    if ! aws s3 mb "s3://$BUCKET_NAME"; then
        echo "Error: Failed to create bucket '$BUCKET_NAME'. Ensure the name is unique and you have permissions."
        exit 1
    fi
fi

# Configure Intelligent-Tiering via Lifecycle Rule
echo "Configuring S3 Lifecycle Rule for Intelligent-Tiering..."
cat > /tmp/lifecycle.json <<EOF
{
    "Rules": [
        {
            "ID": "MoveToIntelligentTiering",
            "Status": "Enabled",
            "Filter": {
                "Prefix": ""
            },
            "Transitions": [
                {
                    "Days": 0,
                    "StorageClass": "INTELLIGENT_TIERING"
                }
            ]
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET_NAME" --lifecycle-configuration file:///tmp/lifecycle.json
rm /tmp/lifecycle.json

# Create IAM User
echo "Creating IAM User '$IAM_USER_NAME'..."
aws iam create-user --user-name "$IAM_USER_NAME"

# Create Policy
POLICY_NAME="${IAM_USER_NAME}-policy"
echo "Creating Policy '$POLICY_NAME' ..."

cat > /tmp/restic_policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF

aws iam put-user-policy --user-name "$IAM_USER_NAME" --policy-name "$POLICY_NAME" --policy-document file:///tmp/restic_policy.json
rm /tmp/restic_policy.json

# Create Access Keys
echo "Creating Access Keys..."
# Request keys and output as tab-separated text: AccessKeyId \t SecretAccessKey
KEY_INFO=$(aws iam create-access-key --user-name "$IAM_USER_NAME" --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)

if [ $? -ne 0 ]; then
    echo "Error creating access keys."
    exit 1
fi

ACCESS_KEY=$(echo "$KEY_INFO" | awk '{print $1}')
SECRET_KEY=$(echo "$KEY_INFO" | awk '{print $2}')

echo ""
echo "----------------------------------------------------------------"
echo "Setup Complete!"
echo "----------------------------------------------------------------"
echo "S3 Bucket: $BUCKET_NAME"
echo "IAM User: $IAM_USER_NAME"
echo ""
echo "Please copy the following into your config/restic.env file:"
echo ""
echo "export AWS_ACCESS_KEY_ID=\"$ACCESS_KEY\""
echo "export AWS_SECRET_ACCESS_KEY=\"$SECRET_KEY\""
echo "export RESTIC_REPOSITORY_REMOTE=\"s3:s3.amazonaws.com/$BUCKET_NAME\""
echo "----------------------------------------------------------------"
echo "WARNING: The Secret Access Key is shown only once. Save it now!"

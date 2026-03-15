#!/bin/bash

# AWS S3 Deployment Script
# Replace with your actual domain and bucket name

DOMAIN="yourdomain.com"
BUCKET_NAME="yourdomain.com"
WEBSITE_PATH="/Users/macuser/Documents/GitHub/ziyotek"

echo "Deploying website to AWS S3..."

# Sync files to S3
aws s3 sync "$WEBSITE_PATH" "s3://$BUCKET_NAME/" \
    --delete \
    --exclude ".git/*" \
    --exclude ".DS_Store" \
    --exclude "*.md" \
    --acl public-read \
    --cache-control "max-age=31536000"

echo "Deployment complete!"
echo "Your website is now live at: https://$DOMAIN"
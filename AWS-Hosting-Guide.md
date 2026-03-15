# AWS Website Hosting Guide with Custom Domain

## Table of Contents
1. [Create AWS Account & Setup](#step-1-create-aws-account--setup)
2. [Register or Configure Domain](#step-2-register-or-configure-domain)
3. [Create S3 Bucket for Website](#step-3-create-s3-bucket-for-website)
4. [Configure CloudFront CDN](#step-4-configure-cloudfront-cdn)
5. [Configure Route 53 DNS](#step-5-configure-route-53-dns)
6. [Upload Website Files](#step-6-upload-website-files)
7. [Final Configuration](#step-7-final-configuration)
8. [Set Up Automatic Deployment](#step-8-set-up-automatic-deployment)
9. [Cost Breakdown](#cost-breakdown)
10. [Quick Commands Summary](#quick-commands-summary)
11. [Important Notes](#important-notes)

---

## Step 1: Create AWS Account & Setup

### 1.1 Sign up for AWS
1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Complete registration with credit card
4. Select "Basic" free tier plan

### 1.2 Verify Identity
1. Check email for verification code
2. Complete phone verification
3. Select support plan (Free tier recommended)

---

## Step 2: Register or Configure Domain

### Option A: Register Domain with AWS Route 53
```bash
# Go to Route 53 console
# Click "Register domain"
# Search for your domain (e.g., samitservices.com)
# Complete purchase ($12-15/year)
```

### Option B: Use Existing Domain
1. Log into your domain registrar
2. Update nameservers to AWS Route 53:
   ```
   ns-1.awsdns-01.com
   ns-2.awsdns-02.net
   ns-3.awsdns-03.org
   ns-4.awsdns-04.co.uk
   ```

---

## Step 3: Create S3 Bucket for Website

### 3.1 Navigate to S3 Console
1. Go to S3 service in AWS Management Console
2. Click "Create bucket"

### 3.2 Configure Bucket Settings
```
Bucket name: yourdomain.com
Region: us-east-1 (or nearest to audience)
Block all public access: UNCHECK (required for website)
Enable version control: YES
```

### 3.3 Enable Static Website Hosting
1. Select your bucket → Properties → Static website hosting
2. Enable: Yes
3. Index document: index.html
4. Error document: error.html

### 3.4 Set Bucket Policy
Add this policy to your bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::yourdomain.com/*"
    }
  ]
}
```

---

## Step 4: Configure CloudFront CDN

### 4.1 Create CloudFront Distribution
1. Go to CloudFront console
2. Click "Create distribution"
3. Origin: S3 bucket (select yourdomain.com.s3.amazonaws.com)
4. Viewer protocol policy: Redirect HTTP to HTTPS
5. Custom SSL certificate: Request ACM certificate

### 4.2 Request SSL Certificate
1. Go to AWS Certificate Manager
2. Request public certificate
3. Add domain names: yourdomain.com, www.yourdomain.com
4. Choose DNS validation
5. Create Route 53 DNS records (automatic)

### 4.3 Update Distribution Settings
```
Alternate domain names (CNAMEs): yourdomain.com, www.yourdomain.com
SSL certificate: Select the ACM certificate
Default root object: index.html
```

---

## Step 5: Configure Route 53 DNS

### 5.1 Create Hosted Zone
1. Go to Route 53 → Hosted zones
2. Click "Create hosted zone"
3. Domain name: yourdomain.com

### 5.2 Create DNS Records

#### Root Domain Record
```
Record Type: A
Record Name: (blank) for root domain
Alias: Yes
Route traffic to: CloudFront distribution
TTL: 300
```

#### WWW Subdomain Record
```
Record Type: A  
Record Name: www
Alias: Yes
Route traffic to: CloudFront distribution
TTL: 300
```

---

## Step 6: Upload Website Files

### Method 1: AWS Management Console
1. Open S3 bucket
2. Upload: index.html, styles.css, script.js, favicon.ico
3. Set permissions to "public read"

### Method 2: AWS CLI (Recommended)

#### Install AWS CLI
```bash
# For macOS
brew install awscli

# For Ubuntu/Debian
sudo apt-get install awscli

# For Windows
# Download from aws.amazon.com/cli
```

#### Configure Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your Secret Access Key
# Enter default region (us-east-1)
# Enter output format (json)
```

#### Sync Website Files
```bash
# Sync website files to S3
aws s3 sync ./your-website-folder/ s3://yourdomain.com/ --acl public-read

# Example command
aws s3 sync /Users/macuser/Documents/GitHub/ziyotek/ s3://samitservices.com/ --acl public-read
```

### Method 3: Deploy Script

Create `deploy.sh`:

```bash
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
```

Make it executable:
```bash
chmod +x deploy.sh
```

---

## Step 7: Final Configuration

### 7.1 Invalidate CloudFront Cache
1. Go to CloudFront distribution
2. Click "Invalidations"
3. Create invalidation: "/*"
4. Reason: Deployment

### 7.2 Test Website
1. Clear browser cache
2. Visit https://yourdomain.com
3. Check SSL certificate
4. Test all pages and functionality

---

## Step 8: Set Up Automatic Deployment

### 8.1 GitHub Actions CI/CD

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS S3

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Deploy to S3
      run: |
        aws s3 sync ./ s3://yourdomain.com/ --delete --exclude ".git/*" --exclude "*.md" --acl public-read

    - name: Invalidate CloudFront
      run: |
        aws cloudfront create-invalidation --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} --paths "/*"
```

### 8.2 Set GitHub Secrets
1. Go to repository settings → Secrets and variables → Actions
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `CLOUDFRONT_DISTRIBUTION_ID`

---

## Cost Breakdown (Monthly)

| Service | Free Tier | Paid Usage | Est. Monthly Cost |
|---------|-----------|------------|------------------|
| S3 Storage | 5 GB | $0.023/GB | $0-1 |
| CloudFront | 100 GB data | $0.085/GB | $0-5 |
| Route 53 | - | $0.50/domain | $0.50 |
| Certificate | - | FREE | $0 |
| **Total** | - | - | **$0.50-6.50** |

---

## Quick Commands Summary

```bash
# Deploy website
./deploy.sh

# Sync specific files
aws s3 sync . s3://yourdomain.com/ --delete --acl public-read

# Check website status
curl -I https://yourdomain.com

# Invalidate CDN cache
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"

# List S3 bucket contents
aws s3 ls s3://yourdomain.com/

# Check CloudFront distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID

# Get bucket policy
aws s3api get-bucket-policy --bucket yourdomain.com
```

---

## Important Notes

### Security
- Never commit AWS credentials to Git
- Use IAM roles instead of root account
- Enable MFA on AWS account
- Restrict bucket access by IP if needed

### DNS Propagation
- Domain changes may take 24-48 hours
- Check propagation with: `dig yourdomain.com`

### SSL Certificate
- Free with AWS Certificate Manager
- Automatic renewal included
- Requires DNS validation

### Monitoring
- Set up CloudWatch alerts for costs
- Monitor S3 storage usage
- Track CloudFront data transfer

### Backups
- Enable S3 version control for file backups
- Regular backups of Route 53 zone files
- Document all configurations

### Performance Optimization
- Enable CloudFront compression
- Use gzip compression on S3
- Optimize images and assets
- Set appropriate cache headers

---

## Troubleshooting

### Common Issues

#### 403 Forbidden Error
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket yourdomain.com

# Update permissions
aws s3api put-bucket-acl --bucket yourdomain.com --acl public-read
```

#### CloudFront Not Updating
```bash
# Force invalidation
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

#### SSL Certificate Issues
- Wait at least 30 minutes after DNS record creation
- Verify domain ownership in AWS Certificate Manager

#### High Costs
- Monitor CloudFront data transfer
- Set billing alerts
- Review S3 storage usage

---

## Additional Resources

### Official AWS Documentation
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [Route 53 Developer Guide](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/)

### Tools & Utilities
- [AWS Management Console](https://console.aws.amazon.com/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/reference/)
- [AWS CloudFormation Templates](https://aws.amazon.com/cloudformation/)

---

## Final Checklist

Before going live, ensure:

- [ ] Domain is properly configured in Route 53
- [ ] S3 bucket policy allows public read access
- [ ] CloudFront distribution is deployed
- [ ] SSL certificate is validated
- [ ] All website files are uploaded
- [ ] DNS records are pointing to CloudFront
- [ ] SSL certificate is properly installed
- [ ] Website loads correctly over HTTPS
- [ ] All pages and functionality work
- [ ] Mobile responsiveness is working
- [ ] Backups are configured
- [ ] Cost monitoring is set up

Once completed, your website will be live at `https://yourdomain.com` with professional CDN performance, SSL security, and automatic deployment capabilities!
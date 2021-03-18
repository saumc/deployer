#!/usr/bin/env bash

# requires: pip install awscli awsebcli

# uncomment to debug
#set -x

fail() {
    echo configuration failed
    exit 1
}

export AWS_DEFAULT_REGION=${AWS_REGION:-ap-south-1}

datetag=$(date +%Y%m%d%H%M)
identifier='deployer'
mkdir -p tmp/$identifier

createappenv=false
creates3=false
uploadapp=true

echo "Creating EBS application $identifier"

# Find the ID of the default VPC
aws ec2 describe-vpcs --filters Name=isDefault,Values=true > tmp/$identifier/defaultvpc.json || fail
vpcid=$(jq -r '.Vpcs[0].VpcId' tmp/$identifier/defaultvpc.json)
echo "default vpc is $vpcid"

if $createappenv ; then
# Create an elasticbeantalk application
aws elasticbeanstalk create-application \
    --application-name $identifier \
    --description "deployer $env $datetag" > tmp/$identifier/ebcreateapp.json || fail
echo "ElasticBeanTalk application created"

# Get the name of the latest Docker solution stack
dockerstack="$(aws elasticbeanstalk list-available-solution-stacks | \
    jq -r '.SolutionStacks[]' | grep -P '.+Amazon Linux.+Docker.+' | head -1)"

# Create the EB API environment
aws elasticbeanstalk create-environment \
    --application-name $identifier \
    --environment-name deployer-api \
    --description "deployer API environment" \
    --tags "Key=Owner,Value=$(whoami)" \
    --solution-stack-name "$dockerstack" \
    --option-settings file://instance-profile.json \
    --tier "Name=WebServer,Type=Standard,Version=''" > tmp/$identifier/ebcreateapienv.json || fail

fi 
apieid=$(jq -r '.EnvironmentId' tmp/$identifier/ebcreateapienv.json)
echo "API environment $apieid is being created"

# Upload the application version
if $creates3 ; then
#aws s3 mb s3://$identifier
aws s3 mb s3://deployer-id
#aws s3 cp app-version-deployer.json s3://$identifier/
aws s3 cp app-version-deployer.json s3://deployer-id/
aws elasticbeanstalk create-application-version \
    --application-name "$identifier" \
    --version-label deployer-api \
    --source-bundle "S3Bucket=deployer-id,S3Key=app-version-deployer.json" > tmp/$identifier/appversion.json
    #--source-bundle "S3Bucket=$identifier,S3Key=app-version-deployer.json" > tmp/$identifier/appversion.json
fi

# Wait for the environment to be ready (green)
echo -n "waiting for environment"
while true; do
    aws elasticbeanstalk describe-environments --environment-id $apieid > tmp/$identifier/$apieid.json
    health="$(jq -r '.Environments[0].Health' tmp/$identifier/$apieid.json)"
    if [ "$health" == "Green" ]; then break; fi
    echo -n '.'
    sleep 10
done
echo

# Deploy the docker container to the instances
if $uploadapp ; then
aws elasticbeanstalk update-environment \
    --application-name $identifier \
    --environment-id $apieid \
    --version-label deployer-api > tmp/$identifier/$apieid.json
fi
url="$(jq -r '.CNAME' tmp/$identifier/$apieid.json)"
echo "Environment is being deployed. Public endpoint is http://$url"

#!/bin/sh

aws configure set profile produser
aws rekognition create-collection --collection-id rider-photos --region eu-west-1
aws s3 mb s3://wildrydesdeployment
aws s3 mb s3://wild-rydes-sfn-module-us-west-2
aws s3 sync ../../test-images s3://wild-rydes-sfn-module-us-west-2/test-images

cd src/lambda-functions/thumbnail
npm install

cd ../../cloudformation
aws cloudformation package \
     --template-file module-setup.yaml \
     --output-template-file template.packaged.yaml \
     --s3-bucket wildrydesdeployment \
      --s3-prefix ImageProcessing \
		 --profile produser
aws cloudformation deploy --template-file template.packaged.yaml --stack-name wildrydes --capabilities CAPABILITY_IAM --region eu-west-1 --profile produser

# Collect output
APIURL=$(aws cloudformation describe-stacks --stack-name wildrydes --query "Stacks[0].Outputs[5].OutputValue" --output text)
STATEMACHINEARN=$(aws cloudformation describe-stacks --stack-name wildrydes --query "Stacks[0].Outputs[7].OutputValue" --output text)
BUCKETNAME=$(aws cloudformation describe-stacks --stack-name wildrydes --query "Stacks[0].Outputs[8].OutputValue" --output text)
echo 'curl -X POST -d \'{"input": "{\"userId\": \"user_a\", \"s3Bucket\":\"$BUCKETNAME\", \"s3Key\": \"1_happy_face.jpg\"}", "stateMachineArn": "$STATEMACHINEARN"}\' $APIURL

# Wait
echo "Press any key to tear down the application again"
read -n 1 -s

# Shutdown
aws cloudformation delete-stack --stack-name wildrydes
aws s3 rm s3://wild-rydes-sfn-module-us-west-2 --recursive
aws s3 rm s3://wildrydesdeployment --recursive
aws rekognition delete-collection --collection-id rider-photos
aws s3 rb s3://wildrydesdeployment
aws s3 rb s3://wild-rydes-sfn-module-us-west-2

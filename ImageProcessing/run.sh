#!/bin/sh

aws configure set profile produser
aws rekognition create-collection --collection-id rider-photos --region eu-west-1
aws s3 mb s3://wildrydesdeployment
aws s3 mb s3://wild-rydes-sfn-module-us-west-2
aws s3 sync test-images s3://wild-rydes-sfn-module-us-west-2/test-images

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
cd ../..

# Collect output
APIURL=$(aws cloudformation describe-stacks --stack-name wildrydes --query "Stacks[0].Outputs[5].OutputValue" --output text)
STATEMACHINEARN=$(aws cloudformation describe-stacks --stack-name wildrydes --query "Stacks[0].Outputs[7].OutputValue" --output text)
BUCKETNAME=$(aws cloudformation describe-stacks --stack-name wildrydes --query "Stacks[0].Outputs[8].OutputValue" --output text)

# Prep loadscript
sed -i "s@URLPLACEHOLDER@$APIURL@g" load.lua
sed -i "s@STATEMACHINEARNPLACEHOLDER@$STATEMACHINEARN@g" load.lua
sed -i "s@BUCKETPLACEHOLDER@$BUCKETNAME@g" load.lua

# Run Load
java -jar httploadgenerator.jar loadgenerator > loadlogs.txt 2>&1 &
./generateConstantLoad.sh 50 600
sleep 10
java -jar httploadgenerator.jar director --ip localhost --load load.csv -o results.csv --lua load.lua --randomize-users -t 128

# Shutdown
aws cloudformation delete-stack --stack-name wildrydes
aws s3 rm s3://wild-rydes-sfn-module-us-west-2 --recursive
aws s3 rm s3://wildrydesdeployment --recursive
aws rekognition delete-collection --collection-id rider-photos
aws s3 rb s3://wildrydesdeployment
aws s3 rb s3://wild-rydes-sfn-module-us-west-2


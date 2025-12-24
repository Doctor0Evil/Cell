AWS ECS Fargate skeleton (staging)

This folder contains a minimal CloudFormation template (`ecs-fargate.yaml`) to create:
- ECR repositories for web and api
- ECS cluster
- ALB skeleton (DNS output)

Usage (example):
1. Prepare VPC and subnets (or use existing).
2. Deploy the template with AWS CLI:
   aws cloudformation deploy --template-file ecs-fargate.yaml --stack-name tryognik-staging --parameter-overrides VpcId=vpc-xxxx SubnetIds="subnet-aaa,subnet-bbb" PublicSubnetIds="subnet-ccc,subnet-ddd"

Notes:
- This is a skeleton to be extended: add task definitions, target groups, listeners, security groups, and IAM roles as required.
- For CI, push images to the created ECR repos and update ECS task definitions to use the new image tags.

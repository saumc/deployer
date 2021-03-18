# Securing DevOps's deployer
A simple API that receives webhook notifications, runs tests and trigger deployments.

Get your own copy
-----------------

To try out the code in this repository, first create a fork in your own github account.

## Replace the namespace

Now before you do anything, edit the file `main.go` and replace `securingdevops` with your dockerhub username on line 50.
```go
if hookData.Repository.Namespace != `securingdevops` {
		httpError(w, http.StatusUnauthorized, "Invalid namespace")
		return
}
```

If your dockerhub username is `bobkelso`, then the code should read
```go
if hookData.Repository.Namespace != `bobkelso` {
		httpError(w, http.StatusUnauthorized, "Invalid namespace")
		return
}
```
When the deployer processes a webhook notification, it makes sure the notification comes from a trusted dockerhub user. You certainly don't want to leave that blank, otherwise anyone could send webhook notifications to your deployer and trigger new deployments.

## Set your own environment

Next, still in main.go, replace the following code with your own, taken from the invoicer's elastic beanstalk environment your created previously.

```go
	params := &elasticbeanstalk.UpdateEnvironmentInput{
		ApplicationName: aws.String("invoicer201707071231"),
		EnvironmentId:   aws.String("e-y8ubep55hp"),
		VersionLabel:    aws.String("invoicer-api"),
}
```
## My notes:
For deployer to be able to update invoicer environment it needs aws access keys. Adding following to the config.yml should work:
(For this the input environment variables are added to circleci configuration; similar to DOCKER_USER and DOCKER_PASS)

mkdir -p ~/.aws
echo "[default]" > ~/.aws/credentials
echo "aws_access_key_id = ${AWS_ACCESS_KEY_ID}" >> ~/.aws/credentials
echo "aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}" >> ~/.aws/credentials

echo "[default]" > ~/.aws/config
echo "region = ap-south-1"  > ~/.aws/config
echo "output = json" > ~/.aws/config


## Flow:
1. Changes in the deployer. finish circleci.
2. deploy to aws  - ./create_ebs_env.sh 
(can try to combine 1 and 2)
3. changes to invoicer github - dockerhub - deployer activated to check AWS infra through webhook 
4. If all ok - invoicer is deployed by the deployer. 
- Ideally only 1 and 3 should be manual
check deployer aws logs to check if the invoicer deployed ok.
- ideally deployer is steady and changes are happening in the inoiver.

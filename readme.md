# Simple Python web app, uses Flask as the web server
templates/index.html prints the hostname and version onto the screen
The Dockerfile specifies the metadata of the app, files, networking, environment
Docker-Compose launches multiple instances of the application for High Availability

Can deploy locally with: 

docker-compose build

docker-compose up

Access each instance in web browser:

Node-01 = http://localhost:5001

Node-02 = http://localhost:5002

Can deploy with Terraform to AWS with: 
terraform init
terraform apply auto-approve

Can build a pipeline with CircleCI 
the .circleci/config.yml beholds the following information:
circleCI version
Terraform image and version
Terraform init job
Terraform plan job 
Terraform apply job 
in addition to workflows stating the init and plan stages
CircleCI project settings -> environment variables setup for AWS integration

![alt text](https://github.com/BekeAtGithub/flaskEC2/blob/master/FlaskEC2.drawio.png)

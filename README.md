## Initial Deployment on AWS EC2 with Terraform and Nginx

### Setting Up AWS EC2 with Terraform

To get started, I deployed my website on an AWS EC2 instance. I chose AWS for its reliable and scalable infrastructure. EC2 provides virtual servers in the cloud, which are highly configurable and suitable for various types of workloads.

I used Terraform to automate the creation of my EC2 instance. Terraform is an infrastructure-as-code tool that allows for consistent and repeatable infrastructure deployment. Using Terraform ensures that the environment setup can be easily reproduced and managed.

Here’s the Terraform configuration I used:

```hcl
provider "aws" {
  region = "ca-central-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2fromami" {
  ami           = "ami-05e86465a5325c170"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  tags = {
    Name = "website"
  }
}
```

### Configuring Nginx for Reverse Proxy

Once the instance was up and running, I set up Nginx as a reverse proxy. Nginx is a powerful web server that can also be used as a reverse proxy, load balancer, and HTTP cache. Using Nginx helps in routing traffic efficiently to my application, improving performance and reliability.

## Streamlining Deployments with Ansible

Deploying updates manually became cumbersome, so I turned to Ansible to automate the process. Ansible is an open-source automation tool that simplifies configuration management, application deployment, and task automation. It allows me to write simple scripts to automate the deployment process, making it more consistent and less error-prone.

Here’s my Ansible playbook:

```yaml
- name: Push code to GitHub and deploy project
  hosts: localhost
  connection: local
  tasks:
    - name: Change to the project directory
      command: git add .
      args:
        chdir: /Users/mufaddalrangwala/Developer/mufaddalrangwala.dev

    - name: Commit changes
      command: git commit -m "Automated commit message"
      args:
        chdir: /Users/mufaddalrangwala/Developer/mufaddalrangwala.dev
      ignore_errors: yes

    - name: Push changes to GitHub
      command: git push -u origin main
      args:
        chdir: /Users/mufaddalrangwala/Developer/mufaddalrangwala.dev

- name: Deploy project on EC2
  hosts: ec2
  become: yes
  tasks:
    - name: Go into instance project
      command: git pull 
      args:
        chdir: /home/ubuntu/mufaddalrangwala.dev

    - name: Build the project
      command: npm run build
      args:
        chdir: /home/ubuntu/mufaddalrangwala.dev
```

The Ansible hosts file looked like this:

```ini
[localhost]
127.0.0.1

[ec2]
15.222.7.165 ansible_user=ubuntu ansible_ssh_private_key_file=/Users/mufaddalrangwala/Desktop/private/website.pem
```
## Transitioning to Docker
To further streamline deployments and manage dependencies, I containerized my application using Docker. Docker is a platform that enables developers to create, deploy, and run applications in containers. Containers are lightweight and contain all the necessary dependencies, making the application portable and consistent across different environments.

I created a Docker image that included both my application and Nginx, then pushed this image to Docker Hub. This allows for easy distribution and version control of the application.

Here’s the Dockerfile:

```dockerfile
FROM node:18-alpine AS build-stage

WORKDIR /app

RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont

COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 80
RUN npm run build

FROM nginx:stable-alpine as production-stage

COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
```
## Moving to GCP Kubernetes

AWS Kubernetes was a paid service, so I moved my project to GCP, which offers $300 in free credits. This allowed me to leverage Kubernetes for better scalability and management. Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications.

### Kubernetes Deployment Configuration

Here’s the Kubernetes deployment file:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mufaddal-info-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mufaddal-info
  template:
    metadata:
      labels:
        app: mufaddal-info
    spec:
      containers:
      - name: mufaddal-info-container
        image: mufaddal16/mufaddalx86:latest
        imagePullPolicy: Always  
        ports:
        - containerPort: 80
```

### Setting Up CI/CD Pipeline with GitLab

To automate deployments, I created a CI/CD pipeline using GitLab CI/CD. Continuous Integration and Continuous Deployment (CI/CD) are practices that allow for frequent, reliable updates by automating the build and deployment process. GitLab CI/CD integrates seamlessly with Docker and Kubernetes, making it an ideal choice for my project.

Here’s the GitLab CI/CD pipeline configuration:

```yaml
image: docker:latest

services:
  - name: docker:dind
    
stages:
  - build-and-push-dh
  - install-gcloud-and-deploy-to-gke

variables:
  DOCKER_IMAGE: mufaddal16/mufaddalx86:$CI_COMMIT_SHORT_SHA
  GKE_CLUSTER:  mufaddal-info
  GKE_ZONE: us-central1-a
  GKE_PROJECT: mufaddalwebsite
  DEPLOYMENT_NAME: mufaddal-info-deployment

build-and-push-to-dockerhub-job:
  stage: build-and-push-dh
  script:
    - echo "Building Image $DOCKER_HUB_URL"
    - docker build -t $DOCKER_IMAGE .
    - echo "Image Built"
    - echo "Pushing Image To DockerHub"
    - docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_TOKEN
    - docker push $DOCKER_IMAGE
    - echo "Image pushed to DockerHub with SHA tag"
    - echo "Tagging image with latest and pushing to DockerHub"
    - docker tag $DOCKER_IMAGE mufaddal16/mufaddalx86:latest
    - docker push mufaddal16/mufaddalx86:latest
    - echo "Image tagged with latest and pushed to DockerHub"

install-gcloud-and-update-cluster-job:
  image: google/cloud-sdk:latest
  stage: install-gcloud-and-deploy-to-gke
  script:
    - echo $GCLOUD_SERVICE_KEY > ${HOME}/gcloud-service-key.json
    - gcloud auth activate-service-account --key-file=${HOME}/gcloud-service-key.json
    - gcloud config set project $GKE_PROJECT
    - gcloud config set compute/zone $GKE_ZONE
    - gcloud container clusters get-credentials $GKE_CLUSTER
    - echo "GCloud Installed and Configured"
    - echo "Deploying to GKE"
    - kubectl set image deployment/$DEPLOYMENT_NAME mufaddal-info-container=$DOCKER_IMAGE
    - kubectl rollout restart deployment/$DEPLOYMENT_NAME
    - echo "Deployment updated and rollout restarted"
    - echo "Should Restart Deployment $DEPLOYMENT_NAME with Image $DOCKER_IMAGE"
```

## Conclusion

Deploying my website has been an enriching journey, transitioning from AWS EC2 to GCP Kubernetes. Each step, from using Terraform and Ansible to containerizing with Docker and managing with Kubernetes, has optimized and simplified my deployment process. This setup now allows me to focus more on development, knowing my deployments are handled efficiently. By leveraging the right tools and technologies, I’ve built a robust and scalable deployment pipeline that ensures my website remains reliable and up-to-date.

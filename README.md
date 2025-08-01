  This CloudFormation template provisions an EC2 instance configured to run a vLLM inference service using Docker. 
  It installs Docker, pulls the vLLM container from a public ECR repository, and launches the Large Language Model (LLM) 
  with Hugging Face Hub token authentication. The instance is customizable via parameters such as instance type, subnet, 
  security group, and SSH key pair.

# aws-soci-installer GitHub Action
AWS Fargate Enables Faster Container Startup using Seekable OCI.

This Action installs the SOCI binary during a GitHub Actions run.

## What is AWS Fargate?
- AWS Fargate is a technology that you can use with Amazon ECS to run containers without having to manage servers or clusters of Amazon EC2 instances. With Fargate, you no longer have to provision, configure, or scale clusters of virtual machines to run containers.
  - [AWS Fargate](https://aws.amazon.com/fargate/)
  
## What is AWS SOCI?
- Seekable OCI (SOCI) is a technology open-sourced by AWS that enables containers to launch faster by lazily loading the container image. SOCI works by creating an index (SOCI Index) of the files within an existing container image.
- This index is a key enabler to launching containers faster, providing the capability to extract an individual file from a container image before downloading the entire archive.
  - [Seekable OCI (SOCI)](https://aws.amazon.com/about-aws/whats-new/2022/09/introducing-seekable-oci-lazy-loading-container-images/)

- ### Here's why you should consider using SOCI:
  - `Faster Container Launches`
  - `Optimized Resource Usage`
  - `No Image Conversion or Digest Changes`
  - `Open Source and Community Collaboration`
  - `Easy Integration with Existing Tools`
  - `Minimized Changes to Workflow`
  - `Performance Improvement`

## Usage
**Note:** Supported only on Linux-based Runners.

Add the following entry to your Github workflow YAML file:

```yaml
uses: iamops-team/aws-soci@v1.0
with:
  registry: 'Registry Name'  # Optional
  registry_user: 'ECR Repository username'  # Optional
  registry_password: 'ECR Repository password'  # Optional
  repo_name: 'ECR Repository Name'  # Optional
  tag_name: 'TAG Name'  # Optional
```

Example using a pinned version:

```yaml
jobs:
  setup:
    runs-on: ubuntu-latest

    permissions: {}

    name: Install soci
    steps:
      - name: Install aws-soci
        uses: iamops-team/aws-soci@v1.0
        with:
          registry: 'Registry Name'
          registry_user: 'ECR Repository username'
          registry_password: 'ECR Repository password'
          repo_name: 'ECR Repository Name'
          tag_name: 'TAG Name'
      - name: Verify install!
        run: soci --version
```

Example using the latest version:

```yaml
jobs:
  setup:
    runs-on: ubuntu-latest

    name: Install aws-soci
    steps:
      - name: Install aws-soci
        uses: iamops-team/aws-soci@v1.0
      - name: Verify install!
        run: soci --version
```

This action does not need any GitHub permission to run, however, if your workflow needs to update, create or perform any
action against your repository, then you should change the scope of the permission appropriately.

Example of a simple workflow for aws ECR:

```yaml
name: SOCI-INDEX-DEMO
on:
  workflow_dispatch:

jobs:
  compile:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      id-token: write
    steps:
      - uses: actions/checkout@v3.5.3

      - name: Configure AWS Credentials
        id: login-aws
        uses: aws-actions/configure-aws-credentials@v2
        with:
        #   role-to-assume:  ${{ secrets.AWS_ROLE_ARN }}
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
        with:
          mask-password: 'true'

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - run: echo "__AWS_REGION__=$(echo "${{ secrets.AWS_REGION }}" | tr '-' '_')" >> $GITHUB_ENV

      - name: Create SOCI INDEX
        uses: iamops-team/aws-soci@v1.0
        with:
          registry: ${{ steps.login-ecr.outputs.registry }}
          registry_user: ${{ steps.login-ecr.outputs[format('docker_username_{0}_dkr_ecr_{1}_amazonaws_com', steps.login-aws.outputs.aws-account-id, env.__AWS_REGION__)] }}
          registry_password: ${{ steps.login-ecr.outputs[format('docker_password_{0}_dkr_ecr_{1}_amazonaws_com', steps.login-aws.outputs.aws-account-id, env.__AWS_REGION__)] }}
          repo_name: 'ECR_Repository_NAME'
          tag_name: 'TAG_NAME'
```

Example of a simple workflow (non-ECR):

```yaml
name: SOCI-INDEX-DEMO
on:
  workflow_dispatch:

jobs:
  compile:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      id-token: write
    steps:
      - uses: actions/checkout@v3.5.3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build, tag, and push the image to Amazon ECR
        id: build-image
        run:
          docker build -t test:v1 .;
          docker push test:v1;

      - name: Login to Container Registry
        uses: docker/login-action@v2.1.0
        with:
          registry: 'xyz.com'
          username: 'test'
          password: 'xxxxxxx'

      - name: Install aws SOCI
        uses: iamops-team/aws-soci@v1.0

      - name: pull the image in containerd
        run: |
          sudo ctr i pull --user $REGISTRY_USER:$REGISTRY_PASSWORD $REGISTRY/$REPO_NAME:$REPOSITORY_TAG

      - name: Create and push soci index
        run: |
          sudo soci create $REGISTRY/$REPO_NAME:$REPOSITORY_TAG
          sudo soci push --user $REGISTRY_USER:$REGISTRY_PASSWORD $REGISTRY/$REPO_NAME:$REPOSITORY_TAG
```

### Optional Inputs
The following optional inputs:

| Input | Description | Required |
| --- | --- | --- |
| `registry` | Docker container registry URL, ex: ECR | no |
| `registry_user` | Docker Container registry username. | no |
| `registry_password` | Docker Container registry password. | no |
| `repo_name` | Docker Container repository name. | no |
| `tag_name` | Docker tag name. | no |

- **References:**
  - [introducing seekable oci lazy loading container images](https://aws.amazon.com/about-aws/whats-new/2022/09/introducing-seekable-oci-lazy-loading-container-images/)
  - [aws fargate container startup seekable oci](https://aws.amazon.com/about-aws/whats-new/2023/07/aws-fargate-container-startup-seekable-oci/)
  - [aws fargate enables faster container startup using seekable oci](https://aws.amazon.com/blogs/aws/aws-fargate-enables-faster-container-startup-using-seekable-oci/)

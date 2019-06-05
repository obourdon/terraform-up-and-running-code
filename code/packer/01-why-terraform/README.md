# Packer example

This folder shows an example [Packer](https://www.packer.io/) template that can be used to create an [Amazon Machine
Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) of an Ubuntu server with Apache, PHP, and
a sample PHP app installed.

For more info, please see Chapter 1, "Why Terraform", of 
*[Terraform: Up and Running](http://www.terraformupandrunning.com)*.

## Pre-requisites

* You must have an [Amazon Web Services (AWS) account](http://aws.amazon.com/).
* You must have [Packer](https://www.packer.io/) installed on your computer but you can also use a docker images (see below).

## Quick start

**Please note that this example will deploy real resources into your AWS account. We have made every effort to ensure 
all the resources qualify for the [AWS Free Tier](https://aws.amazon.com/free/), but we are not responsible for any
charges you may incur.** 

Configure your [AWS access 
keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) as 
environment variables:

```
export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

If for some reason, you have deleted the default subnets and/or internet gateways and routes in your AWS region, then
the following minimal steps are also required in order to be able to build the AMI using Packer:

    $ vpcid=$(AWS_PROFILE=sqsc aws ec2 create-vpc --cidr-block 192.168.0.0/16 | jq -r '.Vpc.VpcId')
    $ subnetid=$(AWS_PROFILE=sqsc aws ec2 create-subnet --vpc-id $vpcid --cidr-block 192.168.1.0/24 | jq -r '.Subnet.SubnetId')
    $ igwid=$(AWS_PROFILE=sqsc aws ec2 create-internet-gateway | jq -r '.InternetGateway.InternetGatewayId')
    $ AWS_PROFILE=sqsc aws ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid
    $ rttblid=$(AWS_PROFILE=sqsc aws ec2 create-route-table --vpc-id $vpcid | jq -r '.RouteTable.RouteTableId')
    $ AWS_PROFILE=sqsc aws ec2 create-route --route-table-id $rttblid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid
    $ AWS_PROFILE=sqsc aws ec2 associate-route-table  --subnet-id $subnetid --route-table-id $rttblid
    $ AWS_PROFILE=sqsc aws ec2 modify-subnet-attribute  --subnet-id $subnetid --map-public-ip-on-launch

a simpler way to achieve this is by running the script and keeping variables in your environment for later usage:

    $ . ./aws_vpc.sh

To build the AMI:

```
packer build webserver.json
```

or if you do not want to install Packer but use the official Docker image from HashCorp:

```
docker run -i -t -v $(pwd):/root -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY hashicorp/packer:light build -var vpcid=$vpcid -var subnetid=$subnetid /root/webserver.json
```

** Important note **: whenever you change region in AWS do not forget that AMI ids are specific to each region, You therefore need
to retrieve the one in your region corresponding to Ubuntu Server Xenial 16.04 amd64 20161020.

```
AWS_DEFAULT_REGION=eu-west-1 aws ec2 describe-images  --filters "Name=name,Values=*hvm-ssd*ubuntu-xenial-16.04-amd64-server-20161020" --query 'Images[*].{ID:ImageId,Name:Name}'
AWS_DEFAULT_REGION=us-east-1 aws ec2 describe-images  --filters "Name=name,Values=*hvm-ssd*ubuntu-xenial-16.04-amd64-server-20161020" --query 'Images[*].{ID:ImageId,Name:Name}'

```

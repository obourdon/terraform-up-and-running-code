#!/usr/bin/env bash

set -e

export AWS_PROFILE=${AWS_PROFILE:-sqsc}

echo "Creating VPC"
vpcid=$(aws ec2 create-vpc --cidr-block 192.168.0.0/16 | jq -r '.Vpc.VpcId')
echo "Creating subnet in VPC"
subnetid=$(aws ec2 create-subnet --vpc-id $vpcid --cidr-block 192.168.1.0/24 | jq -r '.Subnet.SubnetId')
echo "Creating internet gateway"
igwid=$(aws ec2 create-internet-gateway | jq -r '.InternetGateway.InternetGatewayId')
echo "Attaching VPC to internet gateway"
aws ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid
echo "Creating route table in VPC"
rttblid=$(aws ec2 create-route-table --vpc-id $vpcid | jq -r '.RouteTable.RouteTableId')
echo "Creating route"
aws ec2 create-route --route-table-id $rttblid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid
echo "Attaching route table to subnet"
aws ec2 associate-route-table  --subnet-id $subnetid --route-table-id $rttblid
echo "Allowing instances to automatically get public IP address when launched in subnet"
aws ec2 modify-subnet-attribute  --subnet-id $subnetid --map-public-ip-on-launch

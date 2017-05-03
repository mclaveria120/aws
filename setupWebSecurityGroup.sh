#!/bin/bash

set -euf -o pipefail

clear

# PARAMETERS
securityGroupName="web"
defaultVPC="vpc-5c03893a"

createSecurityGroup(){
	echo "Checking existance of $securityGroupName security group"
	
	if aws ec2 describe-security-groups --output=json | jq '.SecurityGroups | .[] | .GroupName' | grep -q "$securityGroupName"; then
	
   			echo "Deleting security group"
			aws ec2 delete-security-group --group-name $securityGroupName

	fi		
	echo "Creating group"

	aws ec2 create-security-group --group-name $securityGroupName --description $securityGroupName
	
}

addInboundRules(){
	echo "Adding Rules for HTTP and HTTPS from anywhere IPv4 and IPv6"
	aws ec2 authorize-security-group-ingress --group-name $securityGroupName  --protocol tcp --port 80 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name $securityGroupName  --protocol tcp --port 443 --cidr 0.0.0.0/0
	#aws ec2 authorize-security-group-ingress --group-name $securityGroupName  --protocol tcp --port 80 --cidr ::/0
	#aws ec2 authorize-security-group-ingress --group-name $securityGroupName  --protocol tcp --port 443 --cidr ::/0
}




createSecurityGroup
addInboundRules

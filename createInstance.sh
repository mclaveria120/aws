#!/bin/bash

set -e

# PARAMETERS

imageid="ami-6edd3078" ##free tire  needed:ami-6edd3078 
numberOfInstances=1
instanceType="t2.small"
ebs="[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10,\"VolumeType\":\"standard\",\"DeleteOnTermination\":false}}]"
keyName="tagName"
subnetId="subnet-3930b305" # subnet-3930b305 us-east-1e #subnet-7b744732 1a

hostedZoneId="Z243R08ALCDDW"

createInstance(){	
	securityGroup=$(aws ec2 describe-security-groups --output=json | jq '.SecurityGroups | .[] | select(.GroupName=="web") | .GroupId'  | cut -d '"' -f2)
    

	aws ec2 run-instances --iam-instance-profile Name=CodeDeployEC2ServiceRole --image-id $imageid --count $numberOfInstances  --security-group-ids $securityGroup  --instance-type $instanceType  --associate-public-ip-address --disable-api-termination --subnet-id $subnetId  --block-device-mappings $ebs --key-name $keyName --user-data file://instance-setup.sh
    echo "Adding Tag"
    aws ec2 create-tags --resources $(aws ec2 describe-instances  --query 'Reservations[0].Instances[0].InstanceId' --output text) --tags Key=TEAM,Value=1
}

checkIp (){
	ip=$(aws ec2 describe-instances  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
}

setARecord(){

	aws route53 change-resource-record-sets --hosted-zone-id $hostedZoneId --change-batch file://dnsRecords.json


}

printJSON(){
	cat <<EOF > dnsRecords.json
	{"Comment":"Updating A record for the zone.",
	  "Changes":[
	    {
	    "Action": "UPSERT",
	    "ResourceRecordSet":{
	        "Name": "domain.",
	        "Type": "A",
	        "TTL": 300,
	        "ResourceRecords":[
	            {
	                "Value": "$ip"
	            }
	        ]
	      }
	    }
	  ]
	}
EOF
}

start(){
	
	echo "Starting instance..."
	
	createInstance

	while true; do

		echo "Waiting 5 seconds for IP..."
		sleep 5
		checkIp
		if [ ! -z "$ip" ]; then
			break
		else
			echo "Not founded. Trying again..."
			sleep 5
		fi

	done

	echo "IP $ip "
	echo "Building Json for updating DNS records"
	printJSON
 	setARecord
	echo "Updating DNS Records..."
	sleep 15
	echo "domain"
	dig domain +short

}

start















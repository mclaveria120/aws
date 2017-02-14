#!/bin/bash

# PARAMETERS

imageid="" ##free tire  needed:ami-6edd3078 
numberOfInstances=1
instanceType="t2.micro"
ebs="[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10,\"VolumeType\":\"standard\",\"DeleteOnTermination\":false}}]"
keyName=""
securityGroup=""
subnetId="" #us-east-1e

hostedZoneId=""
domainName=""

createInstance(){	
	aws ec2 run-instances --image-id $imageid --count $numberOfInstances  --security-group-ids $securityGroup  --instance-type $instanceType  --associate-public-ip-address --disable-api-termination --subnet-id $subnetId  --block-device-mappings $ebs --key-name $keyName
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
	        "Name": "$domainName",
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
	echo "$domainName"
	dig $domainName

}

start















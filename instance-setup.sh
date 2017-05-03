#!/bin/bash
apt-get -y update
apt-get -y install awscli
apt-get -y install ruby
cd /home/ubuntu
aws s3 cp s3://aws-codedeploy-us-east-1/latest/install . --region us-east-1
chmod +x ./install
./install auto

cd /home/ubuntu
sudo apt-get update
sudo apt-get install default-jdk -y
java -version

sudo apt install mysql-client-core-5.7 -y

sudo mkdir /opt/tomcat
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
wget http://www-eu.apache.org/dist/tomcat/tomcat-8/v8.0.43/bin/apache-tomcat-8.0.43.tar.gz
sudo tar -xzvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/
sudo rm -rf  /opt/tomcat/webapps/*
#sed -i 's/8080/80/g' /opt/tomcat/conf/server.xml

cat <<EOF >/etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/awslogs.service
[Unit]
Description=The CloudWatch Logs agent
After=rc-local.service

[Service]
Type=simple
Restart=always
KillMode=process
TimeoutSec=infinity
PIDFile=/var/awslogs/state/awslogs.pid
ExecStart=/var/awslogs/bin/awslogs-agent-launcher.sh --start --background --pidfile $PIDFILE --user awslogs --chuid awslogs &

[Install]
WantedBy=multi-user.target
EOF



mkdir /home/ubunt/components
mkdir /home/ubunt/components/frontend


sudo apt-get install python -y

curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O 

cat <<EOF >/opt/awslogs.conf
[general]
state_file = /var/awslogs/state/agent-state

[host.log]
datetime_format = %d/%b/%Y:%H:%M:%S
file = /opt/tomcat/logs/host.log
buffer_duration = 5000
log_stream_name = {hostname}host.log
initial_position = end_of_file
log_group_name = Instances

[catalina.out]
datetime_format = %d/%b/%Y:%H:%M:%S
file = /opt/tomcat/logs/catalina.out
buffer_duration = 5000
log_stream_name = {hostname}_catalina.out
initial_position = end_of_file
log_group_name = Instances
EOF


sudo python ./awslogs-agent-setup.py  --non-interactive --region us-east-1  --configfile /opt/awslogs.conf

sleep 7

sudo service awslogs start

sudo systemctl daemon-reload
#sudo iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
#sudo iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
#sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8080
#sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080

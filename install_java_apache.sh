#!/bin/bash

echo '[START]Installing Java SDK'
yes Y | apt-get update
yes Y | apt-get install default-jdk
echo '[END]Installed Java SDK'

echo '[START]Installing curl'
yes Y | apt-get install curl
echo '[END]Installed curl'

echo '[START]Installing git'
yes Y | apt-get install git
echo '[END]Installed git'


echo '[START]Creating groupuser tomcat and user tomcat for Apache Tomcat server server'

tomcat_user='tomcat'
user_exists=$(id -u $tomcat_user > /dev/null 2>&1; echo $?) 
group_exists=$(id -g $tomcat_user > /dev/null 2>&1; echo $?)

if [ $group_exists == 1 ]; then
 echo '[RUNNING]Creating tomcat usergroup'
 groupadd $tomcat_user
 echo '[RUNNING]Succesfully created tomcat usergroup'
else
 echo '[RUNNING]Tomcat usergroup already exists'
fi

if [ $user_exists == 1 ]; then
 echo '[RUNNING]Creating tomcat user'
 useradd -s /bin/false -g $tomcat_user -d '/opt/$tomcat' $tomcat_user
 echo '[RUNNING]Succesfully created tomcat user'
else
 echo '[RUNNING]Tomcat user already exists'
fi


echo '[START]Installing Apache Tomcat'
cd /tmp
wget $1
sudo mkdir /opt/tomcat
sudo tar -xzvf $2 -C /opt/tomcat --strip-components=1
echo '[END]Installing Apache Tomcat'


echo '[START]Setting permissions'

#Give the tomcat group ownership over the entire installation directory
cd /opt/tomcat
chgrp -R tomcat /opt/tomcat

#Next, give the tomcat group read access to the conf directory and all of its contents, and execute access to the directory itself
chmod -R g+r conf
chmod g+x conf

#Make the tomcat user the owner of the webapps, work, temp, and logs directories
chown -R tomcat webapps/ work/ temp/ logs/

echo '[END]Permissions were set'

echo '[START]Configuring Tomcat Service Content file'
java_path_temp=$(sudo update-java-alternatives -l)
for word in $java_path_temp
do
  local_java_path=$word
done
local_java_path="${local_java_path}/jre"
echo $local_java_path


tomcat_service_content="[Unit]\r\n
Description=Apache Tomcat Web Application Container\r\n
After=network.target\r\n
\r\n
[Service]\r\n
Type=forking\r\n
\r\n
Environment=JAVA_HOME=${local_java_path}\r\n
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid\r\n
Environment=CATALINA_HOME=/opt/tomcat\r\n
Environment=CATALINA_BASE=/opt/tomcat\r\n
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'\r\n
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'\r\n
\r\n
ExecStart=/opt/tomcat/bin/startup.sh\r\n
ExecStop=/opt/tomcat/bin/shutdown.sh\r\n
\r\n
User=tomcat\r\n
Group=tomcat\r\n
UMask=0007\r\n
RestartSec=10\r\n
Restart=always\r\n
\r\n
[Install]\r\n
WantedBy=multi-user.target"
echo -e $tomcat_service_content > /etc/systemd/system/tomcat.service

echo '[END]Configured Tomcat Service Content file'

#Reload systemd daemon
sudo systemctl daemon-reload

#start server 
# sudo systemctl start tomcat

#check status
# sudo systemctl status tomcat

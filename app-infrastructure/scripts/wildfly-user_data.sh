#!/bin/bash
sudo yum install wget -y
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U amazon-cloudwatch-agent.rpm
sudo touch /opt/aws/amazon-cloudwatch-agent/etc/custom_config.json
echo "

{
	\"metrics\": {
		
		\"metrics_collected\": {
			\"cpu\": {
				\"measurement\": [
					\"cpu_usage_idle\",
					\"cpu_usage_user\",
					\"cpu_usage_system\"
				],
				\"metrics_collection_interval\": 300,
				\"totalcpu\": false
			},
			\"disk\": {
				\"measurement\": [
					\"used_percent\"
				],
				\"metrics_collection_interval\": 600,
				\"resources\": [
					\"*\"
				]
			},
			\"mem\": {
				\"measurement\": [
   				\"mem_used_percent\",
               \"mem_available\",
               \"mem_available_percent\",
               \"mem_total\",
               \"mem_used\"
				],
				\"metrics_collection_interval\": 600
			}
		}
	},
	\"logs\":{
   \"logs_collected\":{
      \"files\":{
         \"collect_list\":[
            {
               \"file_path\":\"/var/log/secure\",
               \"log_group_name\":\"secure\",
               \"log_stream_name\":\"{instance_id} secure\",
               \"timestamp_format\":\"UTC\"
            },
            {
               \"file_path\":\"/var/log/messages\",
               \"log_group_name\":\"messages\",
               \"log_stream_name\":\"{instance_id} messages\",
               \"timestamp_format\":\"UTC\"
            },
						{
               \"file_path\":\"/var/log/audit/audit.log\",
               \"log_group_name\":\"audit.log\",
               \"log_stream_name\":\"{instance_id} audit.log\",
               \"timestamp_format\":\"UTC\"
            },
						{
               \"file_path\":\"/var/log/yum.log\",
               \"log_group_name\":\"yum.log\",
               \"log_stream_name\":\"{instance_id} yum.log\",
               \"timestamp_format\":\"UTC\"
            },
            {
               \"file_path\":\"/var/log/wildfly-docker-logs/*\",
               \"log_group_name\":\"wildfly-logs\",
               \"log_stream_name\":\"{instance_id} ${stack_githash} wildfly-app-logs \",
               \"timestamp_format\":\"UTC\"
            }
         ]
      }
		}
	}


}

" > /opt/aws/amazon-cloudwatch-agent/etc/custom_config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/custom_config.json  -s

#!/bin/bash

ACTIVATIONURL='dsm://dsm01.dbmi-datastage.local:4120/'
MANAGERURL='https://dsm01.dbmi-datastage.local:443'
CURLOPTIONS='--silent --tlsv1.2'
linuxPlatform='';
isRPM='';

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo You are not running as the root user.  Please try again with root privileges.;
    logger -t You are not running as the root user.  Please try again with root privileges.;
    exit 1;
fi;

if ! type curl >/dev/null 2>&1; then
    echo "Please install CURL before running this script."
    logger -t Please install CURL before running this script
    exit 1
fi

curl $MANAGERURL/software/deploymentscript/platform/linuxdetectscriptv1/ -o /tmp/PlatformDetection $CURLOPTIONS --insecure

if [ -s /tmp/PlatformDetection ]; then
    . /tmp/PlatformDetection
else
    echo "Failed to download the agent installation support script."
    logger -t Failed to download the Deep Security Agent installation support script
    exit 1
fi

platform_detect
if [[ -z "$${linuxPlatform}" ]] || [[ -z "$${isRPM}" ]]; then
    echo Unsupported platform is detected
    logger -t Unsupported platform is detected
    exit 1
fi

echo Downloading agent package...
if [[ $isRPM == 1 ]]; then package='agent.rpm'
    else package='agent.deb'
fi
curl -H "Agent-Version-Control: on" $MANAGERURL/software/agent/$${runningPlatform}$${majorVersion}/$${archType}/$package?tenantID= -o /tmp/$package $CURLOPTIONS --insecure

echo Installing agent package...
rc=1
if [[ $isRPM == 1 && -s /tmp/agent.rpm ]]; then
    rpm -ihv /tmp/agent.rpm
    rc=$?
elif [[ -s /tmp/agent.deb ]]; then
    dpkg -i /tmp/agent.deb
    rc=$?
else
    echo Failed to download the agent package. Please make sure the package is imported in the Deep Security Manager
    logger -t Failed to download the agent package. Please make sure the package is imported in the Deep Security Manager
    exit 1
fi
if [[ $${rc} != 0 ]]; then
    echo Failed to install the agent package
    logger -t Failed to install the agent package
    exit 1
fi

echo Install the agent package successfully

sleep 15
/opt/ds_agent/dsa_control -r
/opt/ds_agent/dsa_control -a $ACTIVATIONURL "policyid:11"
# /opt/ds_agent/dsa_control -a dsm://dsm01.dbmi-datastage.local:4120/ "policyid:11"

echo "started cloudwatch agent"
for i in 1 2 3 4 5; do echo "trying to download docker image from s3://${stack_s3_bucket}/releases/jenkins_pipeline_build_${stack_githash}/pic-sure-wildfly.tar.gz" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/releases/jenkins_pipeline_build_${stack_githash}/pic-sure-wildfly.tar.gz . && break || sleep 60; done
echo "pulled wildfly docker image"
for i in 1 2 3 4 5; do echo "trying to download standalone.xml from s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/standalone.xml" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/standalone.xml /home/centos/standalone.xml && break || sleep 60; done
echo "pulled standalone"
for i in 1 2 3 4 5; do echo "trying to download schema from s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/pic-sure-schema.sql" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/pic-sure-schema.sql /home/centos/pic-sure-schema.sql && break || sleep 45; done
echo "pulled pic-sure-schema"
for i in 1 2 3 4 5; do echo "trying to download mysql_module from s3://${stack_s3_bucket}/modules/mysql/module.xml /home/centos/mysql_module.xml" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/modules/mysql/module.xml /home/centos/mysql_module.xml && break || sleep 45; done
echo "pulled mysql_module"
for i in 1 2 3 4 5; do echo "trying to download driver from s3://${stack_s3_bucket}/modules/mysql/mysql-connector-java-5.1.38.jar" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/modules/mysql/mysql-connector-java-5.1.38.jar /home/centos/mysql-connector-java-5.1.38.jar && break || sleep 45; done
echo "pulled mysql driver"
for i in 1 2 3 4 5; do echo "trying to download fence mapping from s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/configs/fence_mapping.json" && sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/configs/fence_mapping.json /home/centos/fence_mapping.json && break || sleep 45; done
echo "pulled fence mapping"

sudo docker run  -d --name schema-init -e "MYSQL_RANDOM_ROOT_PASSWORD=yes" --rm mysql 
sudo docker exec -i schema-init mysql -hpicsure-db.${target-stack}.datastage.hms.harvard.edu -uroot -p${mysql-instance-password} < /home/centos/pic-sure-schema.sql
sudo docker stop schema-init
echo "init'd mysql schemas"

WILDFLY_IMAGE=`sudo docker load < pic-sure-wildfly.tar.gz | cut -d ' ' -f 3`
JAVA_OPTS="-Xms1024m -Xmx2g -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m -Djava.net.preferIPv4Stack=true"
sudo docker run --name=wildfly \
-v /var/log/wildfly-docker-logs/:/opt/jboss/wildfly/standalone/log \
-v /home/centos/standalone.xml:/opt/jboss/wildfly/standalone/configuration/standalone.xml \
-v /home/centos/fence_mapping.json:/usr/local/docker-config/fence_mapping.json \
-v /home/centos/mysql_module.xml:/opt/jboss/wildfly/modules/system/layers/base/com/sql/mysql/main/module.xml  \
-v /home/centos/mysql-connector-java-5.1.38.jar:/opt/jboss/wildfly/modules/system/layers/base/com/sql/mysql/main/mysql-connector-java-5.1.38.jar \
-v /var/log/wildfly-docker-os-logs/:/var/log \
-p 8080:8080 -e JAVA_OPTS="$JAVA_OPTS" -d $WILDFLY_IMAGE

sudo docker logs -f wildfly > /var/log/wildfly-docker-logs/wildfly.log &

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" --silent http://169.254.169.254/latest/meta-data/instance-id)
sudo /usr/local/bin/aws --region=us-east-1 ec2 create-tags --resources $${INSTANCE_ID} --tags Key=InitComplete,Value=true


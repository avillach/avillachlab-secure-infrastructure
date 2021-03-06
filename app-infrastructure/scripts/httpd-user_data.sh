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
               \"file_path\":\"/var/log/httpd-docker-logs/*\",
               \"log_group_name\":\"httpd-logs\",
               \"log_stream_name\":\"{instance_id} ${stack_githash} httpd-app-logs \",
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

mkdir -p /usr/local/docker-config/cert
mkdir -p /var/log/httpd-docker-logs/ssl_mutex
for i in 1 2 3 4 5 6 7 8 9; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/releases/jenkins_pipeline_build_${stack_githash}/pic-sure-ui.tar.gz . && break || sleep 45; done
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/httpd-vhosts.conf /usr/local/docker-config/httpd-vhosts.conf && break || sleep 15; done
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/certs/httpd/server.chain /usr/local/docker-config/cert/server.chain && break || sleep 15; done
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/certs/httpd/server.crt /usr/local/docker-config/cert/server.crt && break || sleep 15; done
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/certs/httpd/server.key /usr/local/docker-config/cert/server.key && break || sleep 15; done
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/psamaui_settings.json /usr/local/docker-config/psamaui_settings.json && break || sleep 15; done
for i in 1 2 3 4 5; do sudo /usr/local/bin/aws --region us-east-1 s3 cp s3://${stack_s3_bucket}/configs/jenkins_pipeline_build_${stack_githash}/picsureui_settings.json /usr/local/docker-config/picsureui_settings.json && break || sleep 15; done

HTTPD_IMAGE=`sudo docker load < pic-sure-ui.tar.gz | cut -d ' ' -f 3`
sudo docker run --name=httpd -v /var/log/httpd-docker-logs/:/usr/local/apache2/logs/ -v /usr/local/docker-config/picsureui_settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json -v /usr/local/docker-config/psamaui_settings.json:/usr/local/apache2/htdocs/psamaui/settings/settings.json -v /usr/local/docker-config/cert:/usr/local/apache2/cert/ -v /usr/local/docker-config/httpd-vhosts.conf:/usr/local/apache2/conf/extra/httpd-vhosts.conf -p 80:80 -p 443:443 -d $HTTPD_IMAGE
sudo docker logs -f httpd > /var/log/httpd-docker-logs/httpd.log &

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" --silent http://169.254.169.254/latest/meta-data/instance-id)
sudo /usr/local/bin/aws --region=us-east-1 ec2 create-tags --resources $${INSTANCE_ID} --tags Key=InitComplete,Value=true


# File: terraform/modules/node-groups/templates/userdata.tpl

#!/bin/bash
set -o xtrace

# Bootstrap and join the cluster
/etc/eks/bootstrap.sh ${cluster_name} \
  --kubelet-extra-args "--node-labels=${node_labels}"

# Configure containerd
cat > /etc/containerd/config.toml << EOF
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
EOF

# Restart containerd
systemctl restart containerd

# Apply performance optimizations
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
sysctl -p

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/containers/*.log",
            "log_group_name": "/aws/eks/${cluster_name}/pods",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Tag instance for better AWS resource organization
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 create-tags \
  --resources $INSTANCE_ID \
  --tags Key=Environment,Value=${environment} \
         Key=Cluster,Value=${cluster_name}
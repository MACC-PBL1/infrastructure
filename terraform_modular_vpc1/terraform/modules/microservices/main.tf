###############################################
# MICROSERVICES - Launch Templates + ASGs + Scaling
###############################################

resource "aws_launch_template" "ms" {
  for_each = var.microservices

  name_prefix   = "${var.name_prefix}-${each.key}-lt-"
  image_id      = var.ami_id
  instance_type = var.microservice_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.microservices_sg_id]

  user_data = base64encode(<<EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3

cat >/usr/local/bin/${each.key}.py <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import socket

NAME = os.environ.get("SVC_NAME", "svc")
PORT = int(os.environ.get("SVC_PORT", "8080"))
HOSTNAME = socket.gethostname()
IP = socket.gethostbyname(HOSTNAME)

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()

        body = f"""
service={NAME}
hostname={HOSTNAME}
ip={IP}
port={PORT}
path={self.path}
"""
        self.wfile.write(body.encode())

    def log_message(self, format, *args):
        return

if __name__ == "__main__":
    httpd = HTTPServer(("0.0.0.0", PORT), H)
    httpd.serve_forever()
PY

cat >/etc/systemd/system/${each.key}.service <<SERVICE
[Unit]
Description=${each.key} simple service
After=network.target

[Service]
Environment=SVC_NAME=${each.key}
Environment=SVC_PORT=${each.value.port}
ExecStart=/usr/bin/python3 /usr/local/bin/${each.key}.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable ${each.key}
systemctl start ${each.key}
EOF
  )


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-${each.key}"
      Role = "microservice"
      Svc  = each.key
    }
  }
}

resource "aws_autoscaling_group" "ms" {
  for_each = var.microservices

  name                      = "${var.name_prefix}-${each.key}-asg"
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size
  health_check_type         = "ELB"
  health_check_grace_period = 60

  vpc_zone_identifier = [
    var.private_subnet_ids[0],
    var.private_subnet_ids[1]
  ]

  launch_template {
    id      = aws_launch_template.ms[each.key].id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arns[each.key]]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-${each.key}"
    propagate_at_launch = true
  }
}

# Target tracking scaling: CPU 목표 ~60%
resource "aws_autoscaling_policy" "cpu_target" {
  for_each = var.microservices

  name                   = "${var.name_prefix}-${each.key}-cpu-target"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.ms[each.key].name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_utilization
  }
}



/opt/terraform-state-server/
│
├── states/                # State files stored here
├── locks/                 # Lock files
├── server.py             # Server code
├── requirements.txt
└── config.yaml           # Optional: auth / TLS settings


sudo mkdir -p /opt/terraform-state-server/{states,locks}
cd /opt/terraform-state-server

sudo apt update
sudo apt install -y python3 python3-pip



cat <<EOF | sudo tee /opt/terraform-state-server/requirements.txt
flask
pyyaml
EOF

sudo pip3 install -r requirements.txt

filess
server --##
yaml

Create a systemd Service

/etc/systemd/system/terraform-state-server.service
[Unit]
Description=Terraform HTTP State Backend Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /opt/terraform-state-server/server.py
Restart=on-failure

[Install]
WantedBy=multi-user.target


sudo systemctl daemon-reload
sudo systemctl enable terraform-state-server
sudo systemctl start terraform-state-server
systemctl status terraform-state-server


####tft files ###

terraform init -reconfigure
terraform apply
journalctl -u terraform-state-server 

PUT /terraform_lock/my_state
POST /terraform_state/my_state
DELETE /terraform_lock/my_state



###check state### 

/opt/terraform-state-server/states/my_state
/opt/terraform-state-server/locks/my_state.lock

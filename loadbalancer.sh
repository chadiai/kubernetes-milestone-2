sudo apt-get update && sudo apt-get install -y haproxy
sudo cp -rf /shared/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy

# cluster.yml.tpl
nodes:
  - address: ${master_ip}
    user: ubuntu
    role:
      - controlplane
      - etcd
      - worker
    ssh_key_path: /home/ubuntu/k8s_key.pem

  - address: ${worker1_ip}
    user: ubuntu
    role:
      - worker
    ssh_key_path: /home/ubuntu/k8s_key.pem

  - address: ${worker2_ip}
    user: ubuntu
    role:
      - worker
    ssh_key_path: /home/ubuntu/k8s_key.pem

# Bypass strict Docker version checks
ignore_docker_version: true

network:
  plugin: canal

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
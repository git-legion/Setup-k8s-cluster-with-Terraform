# cluster.yml.tpl
nodes:
  - address: ${master_ip}
    user: ubuntu
    role:
      - controlplane
      - etcd
      - worker
    ssh_key_path: /home/ubuntu/id_rsa
    hostname_override: master

  - address: ${worker1_ip}
    user: ubuntu
    role:
      - worker
    ssh_key_path: /home/ubuntu/id_rsa
    hostname_override: worker-1

  - address: ${worker2_ip}
    user: ubuntu
    role:
      - worker
    ssh_key_path: /home/ubuntu/id_rsa
    hostname_override: worker-2

# Bypass strict Docker version checks
ignore_docker_version: true

network:
  plugin: canal
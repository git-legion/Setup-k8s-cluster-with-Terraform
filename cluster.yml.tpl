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

# Ensures the API server certificate includes the Public IP
authentication:
  strategy: x509
  sans:
    - ${master_public_ip}

ignore_docker_version: true

network:
  plugin: canal
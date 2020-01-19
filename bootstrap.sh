#!/bin/bash

# 00
rm ./*.pem ./*.json ./*.csr

curl -sfL https://get.k3s.io | sh -

mkdir /home/vagrant/.kube
sudo cp -p /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc


#!/bin/bash

FRIGATE_BW_ID=d53d3de4-83ce-41b2-9c39-f8873900cebf
ANNKE_BW_ID=b871b5cb-54b3-4e67-b041-bdc4f18e384c

source ~/.bw-session &> /dev/null
while [ "$(bw status 2>/dev/null | jq -r '.status')" != "unlocked" ]; do
    bw config server https://vault.kennedn.com &> /dev/null
    echo "export BW_SESSION=$(bw unlock --raw)" > ~/.bw-session
    source ~/.bw-session
done
bw sync &> /dev/null

read -r HTPASSWD_USER HTPASSWD_PASSWORD < <(bw get item ${FRIGATE_BW_ID} | jq -r '.login | [.username, .password] | join(" ")' )

HTPASSWD="auth=$(htpasswd -nb "${HTPASSWD_USER}" "${HTPASSWD_PASSWORD}")"

kubectl delete secret frigate-basic-auth &> /dev/null
kubectl create secret generic frigate-basic-auth --from-literal=${HTPASSWD}

read -r FRIGATE_RTSP_USER FRIGATE_RTSP_PASSWORD < <(bw get item ${ANNKE_BW_ID} | jq -r '.login | [.username, .password] | join(" ")' )

kubectl delete secret frigate &> /dev/null
kubectl create secret generic frigate --from-literal="FRIGATE_RTSP_USER=${FRIGATE_RTSP_USER}" --from-literal="FRIGATE_RTSP_PASSWORD=${FRIGATE_RTSP_PASSWORD}"

#microk8s.kubectl patch -n ingress cm/nginx-ingress-tcp-microk8s-conf --type='merge' -p '{
#  "data":{
#    "8555":"default/frigate:8555",
#    "8554":"default/frigate:8554"
#  }
#}'
#microk8s.kubectl patch -n ingress cm/nginx-ingress-udp-microk8s-conf --type='merge' -p '{
#  "data":{
#    "8555":"default/frigate:8555",
#    "8554":"default/frigate:8554"
#  }
#}'
#microk8s.kubectl patch ds -n ingress nginx-ingress-microk8s-controller --type='json' -p '[
#  {
#    "op": "add", 
#    "path": "/spec/template/spec/containers/0/ports/-", 
#    "value": {
#      "containerPort": 8555, 
#      "hostPort": 8555, 
#      "name": "frigate-tcp", 
#      "protocol": "TCP"
#    }
#  },
#  {
#    "op": "add", 
#    "path": "/spec/template/spec/containers/0/ports/-", 
#    "value": {
#      "containerPort": 8555, 
#      "hostPort": 8555, 
#      "name": "frigate-udp", 
#      "protocol": "UDP"
#    }
#  }
#]'
#microk8s.kubectl patch ds -n ingress nginx-ingress-microk8s-controller --type='json' -p '[
#  {
#    "op": "add", 
#    "path": "/spec/template/spec/containers/0/ports/-", 
#    "value": {
#      "containerPort": 8554, 
#      "hostPort": 8554, 
#      "name": "rtsp-tcp", 
#      "protocol": "TCP"
#    }
#  },
#  {
#    "op": "add", 
#    "path": "/spec/template/spec/containers/0/ports/-", 
#    "value": {
#      "containerPort": 8554, 
#      "hostPort": 8554, 
#      "name": "rtsp-udp", 
#      "protocol": "UDP"
#    }
#  }
#]'

helm upgrade --install frigate ./blakeshome-charts/charts/frigate -f values.yaml

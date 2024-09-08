kubectl exec -it deployment/frigate -- cat /config/config.yml 2>/dev/null | yq eval '.config |= load("/dev/stdin")' values.yaml > .values.yaml
cp values.yaml .values.yaml.bak
mv .values.yaml values.yaml
sed -i 's/^config:/config: |/' values.yaml

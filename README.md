Harbor to manage docker images and helm charts:

```bash
sudo vi /etc/hosts 
# add harbor.fidget.local to the master url.

helm repo add harbor https://helm.goharbor.io
helm fetch harbor/harbor --untar
```

Edit harbor/values.yaml and change the external url in https://harbor.fidget.local



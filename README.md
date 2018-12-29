# docker-hook
Send docker events by web hook

## Use

```
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  
  reflectivecode/docker-alerter
```

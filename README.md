# wafflebot
They serve pancakes in hell.

## To Run

Build Docker image ```docker-compose build```

Run and Attach: ```docker-compose up```

Run and Daemonize: ```docker-compose up -d``` 

Stop: ```docker-compose down --volumes```


## Trouble Shooting Tips

If you get `WARNING: IPv4 forwarding is disabled. Networking will not work`

Add the following to ```/etc/sysctl.conf```:
```net.ipv4.ip_forward=1```

Then the network service and validated the setting:

# systemctl restart network
# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1

https://stackoverflow.com/questions/41453263/docker-networking-disabled-warning-ipv4-forwarding-is-disabled-networking-wil

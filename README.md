# wafflebot
They serve pancakes in hell.


## Run

Build Docker image ```docker-compose build```

Run and Attach: ```docker-compose up```

Run and Daemonize: ```docker-compose up -d``` 

Stop: ```docker-compose down --volumes```


## Usage in Slack

```@wafflebot help``` Display this help message

```@wafflebot analyze <text>``` Performs some pattern matching, character counts, and numerical sequence search.

```@wafflebot watch <url>``` Add url to watch file. 

```@wafflebot get twitter <@username> <number of tweets>``` Dump last n tweets.

_All other messages are responded to in chatbot mode_ :robot_face:


## Trouble Shooting Tips

If you get `WARNING: IPv4 forwarding is disabled. Networking will not work`

Add the following to ```/etc/sysctl.conf```:

```net.ipv4.ip_forward=1```

Then the network service and validated the setting:

&#35; systemctl restart network

&#35; sysctl net.ipv4.ip_forward

net.ipv4.ip_forward = 1

https://stackoverflow.com/questions/41453263/docker-networking-disabled-warning-ipv4-forwarding-is-disabled-networking-wil

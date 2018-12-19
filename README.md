# docker-team-fortress-2-splunk
Build a docker image of a Team Fortress 2 server that can optionally send data to a external Splunk Server using a Splunk Forwarder

# Overview

Create a docker image for Team Fortress 2 that can optionally send data to a external Splunk Server (not in docker image) using a Splunk Forwarder (in the docker image). Tested sending data to Splunk Cloud and on-premise Splunk from local machine.

Configuring the location of the Splunk Server can be determined at runtime for simple examples, for more complex examples some of the forwarder configuration can be baked into the docker image itself. Useful for when dealing with certificates in the forwarder.

# To Build

Run ```docker build .``` in the same directory as the Dockerfile.

Optionally a Splunk Forwarder app can be baked into the docker image by updating the contents of ```./files/splunk/tf2_forwarder_app```
This is useful when more complex forwarder configurations are required for example including certificates ( if using certificates ensure the correct path names are defined in outputs.conf )

# To Run

Overview of docker run parameters

- ```-p 27015:27015/udp``` => required for Team Fortress 2 game clients to connect team fortress 2 server
- ```-e TEAM_FORTRESS_2_CONFIG=<tf2_config>``` => setting the default game mode. Current modes are casual, tournament, training (training is default)
- ```-e TEAM_FORTRESS_2_SV_PASSWORD=<player_password>``` => password for Team Fortress 2 game clients to connect to team fortress 2 server. By default no password is required
- ```-p 27015:27015``` => required for Team Fortress 2 admin access to server
- ```-e TEAM_FORTRESS_2_RCON_PASSWORD=<admin_password>``` => Team Fortress 2 admin password for RCON console
- ```-p 9997:9997``` => required so data can be sent to Splunk server from docker image
- ```-e SPLUNK_FORWARDER_INDEX=<index>``` => required to send data to Splunk, the index that data is written to in Splunk
- ```-e SPLUNK_FORWARDER_SOURCETYPE=<source>``` => required to send data to Splunk, the sourcetype that data is written to in Splunk 
- ```-e SPLUNK_FORWARDER_HOST=<host>``` => required to send data to Splunk, the forwarder that data is written to in Splunk
- ```-e SPLUNK_FORWARDER_SERVER_PORT=<server_port>``` => required to send data to Splunk if not baked into Splunk Forwarder app. It will be in the format of splunk.example.com:9997
  
## Run Examples

- start Team Fortress 2 without sending data to Splunk
  - ```docker run -p 27015:27015/udp <image_id>```

- start Team Fortress 2 in specific game mode current modes are casual, tournament, training (training is default) without sending data to Splunk 
  - ```docker run -p 27015:27015/udp -e TEAM_FORTRESS_2_CONFIG=<tf2_config> <image_id>```

- start Team Fortress 2 setting game password for players without sending data to Splunk
  - ```docker run -p 27015:27015/udp -e TEAM_FORTRESS_2_SV_PASSWORD=<player_password> <image_id>```

- start Team Fortress 2 setting game password for players and admin user (requires TCP port 27015 open) without sending data to Splunk
  - ```docker run -p 27015:27015/udp -p 27015:27015 -e TEAM_FORTRESS_2_SV_PASSWORD=<player_password> -e TEAM_FORTRESS_2_RCON_PASSWORD=<admin_password> <image_id>```

- start Team Fortress 2 and send data Splunk Server - SPLUNK_FORWARDER_SERVER_PORT will be format of splunk.example.com:9997 and required when on forwarder has been been pre-baked into image
  - ```docker run -p 27015:27015/udp -p 9997:9997 -e SPLUNK_FORWARDER_INDEX=<index> -e SPLUNK_FORWARDER_SOURCETYPE=<source> -e SPLUNK_FORWARDER_HOST=<host> -e SPLUNK_FORWARDER_SERVER_PORT=<server_port> <image_id>```

- start Team Fortress 2 and send data Splunk Server when using an existing an existing baked in splunk forwarder app
  - ```docker run -p 27015:27015/udp -p 9997:9997 -e SPLUNK_FORWARDER_INDEX=<index> -e SPLUNK_FORWARDER_SOURCETYPE=<source> -e SPLUNK_FORWARDER_HOST=<host> <image_id>```

- defining everything (requiring pre-baked forwarder app)
  - ```docker run -p 27015:27015/udp -p 27015:27015 -p 9997:9997 -e TEAM_FORTRESS_2_CONFIG=<tf2_config> -e TEAM_FORTRESS_2_SV_PASSWORD=<player_password> -e TEAM_FORTRESS_2_RCON_PASSWORD=<admin_password> -e SPLUNK_FORWARDER_INDEX=<index> -e SPLUNK_FORWARDER_SOURCETYPE=<source> -e SPLUNK_FORWARDER_HOST=<host> <image_id>```
  

- defining everything (not requiring pre-baked forwarder app)
  - ```docker run -p 27015:27015/udp -p 27015:27015 -p 9997:9997 -e TEAM_FORTRESS_2_CONFIG=<tf2_config> -e TEAM_FORTRESS_2_SV_PASSWORD=<player_password> -e TEAM_FORTRESS_2_RCON_PASSWORD=<admin_password> -e SPLUNK_FORWARDER_INDEX=<index> -e SPLUNK_FORWARDER_SOURCETYPE=<source> -e SPLUNK_FORWARDER_HOST=<host> -e SPLUNK_FORWARDER_SERVER_PORT=<server_port> <image_id>```

# Alternative build and run

Run ```docker-compose up``` against the docker-compose.yml file to create a build directly from this GitHub listing. Running ```docker-compose down``` will stop the running docker image. Arguments can be passed in as before.

# Notes

* Both Team Fortress 2 server and Splunk Forwarder are run as the same (non-root) user
* Checks for Team Fortress 2 server updates on container start up and every 5 minutes
* when configured to send data to Splunk in default mode (training) a constant stream of events will be sent to the Splunk Server due to AI bots fighting

# Other links

- https://wiki.teamfortress.com/wiki/Servers - wiki for setting up Team Fortress 2
- https://linuxgsm.com/ - ease Team Fortress 2 server set up
- https://store.steampowered.com/app/440/Team_Fortress_2/ - setting up Team Fortress 2 client in Steam
- https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/Abouttheuniversalforwarder - documentation on setting up Splunk Forwarder
- https://splunkbase.splunk.com/app/1605/ - Splunk app (for Splunk Server) that works against data created by Team Fortress 2

# docker-team-fortress-2-splunk
Build a docker image of a Team Fortress 2 server that can optionally send data to a external Splunk Server using a Splunk Forwarder

Notes
=====

Both TF2 and Splunk Forwarder are run as the same (non-root) user

Checks for TF2 updates on container start up and every 5 minutes

To Build
========

docker build .

Optionally a Splunk Forwarder app can be baked into the docker image by updating the contents of ./files/splunk/tf2_forwarder_app
This is useful when more complex forwarder configurations are required for example including certificates ( if using certificates ensure the correct path names are defined in outputs.conf )

To Run
======

Overview of docker run parameters

-p 27015:27015/udp  => required for team fortress 2 game clients to connect team fortress 2 server
-e TEAM_FORTRESS_2_CONFIG=<tf2_config> => setting the default game mode. Current modes are casual, tournament, training (training is default)
-e TEAM_FORTRESS_2_SV_PASSWORD=<player_password> => password for team fortress 2 game clients to connect to team fortress 2 server. By default no password is required
-p 27015:27015 => required for team fortress 2 admin access to server
-e TEAM_FORTRESS_2_RCON_PASSWORD=<admin_password> => team fortress 2 admin password
-p 9997:9997 => required so data can be sent to Splunk server
-e SPLUNK_FORWARDER_INDEX=<index> => required to send data to Splunk, the index that data is written to in Splunk
-e SPLUNK_FORWARDER_SOURCETYPE=<source> => required to send data to Splunk, the sourcetype that data is written to in Splunk 
-e SPLUNK_FORWARDER_HOST=<host> => required to send data to Splunk, the forwarder that data is written to in Splunk
-e SPLUNK_FORWARDER_SERVER_PORT=<server_port> => required to send data to Splunk if not baked into Splunk Forwarder app

#!/bin/bash

#
# Author: Mark Sivill - Splunk
#
# Start up script when docker image runs
#

#
# TF2_HOME is set in docker image
# SPLUNK_HOME is set in docker image
#

  #
  # optionally override location of Splunk Server where data will be sent
  # this should be done if universal forwarder configuration has not been
  # baked in docker image already
  #
  if [ -z ${SPLUNK_FORWARDER_SERVER_PORT+x} ]
  then

    echo "***** Not setting up local outputs for Splunk Forwarder"

  else

    echo "***** Setting up local outputs for Splunk Forwarder"

    {
      echo "[tcpout]"
      echo "defaultGroup = default-autolb-group"
      echo "[tcpout:default-autolb-group]"
      echo "server = $SPLUNK_FORWARDER_SERVER_PORT"
      echo "[tcpout-server://${SPLUNK_FORWARDER_SERVER_PORT}]"
    } > $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local/outputs.conf

  fi

  #
  # record if there is a valid outputs.conf
  #
  if [ ! -f $SPLUNK_HOME/etc/apps/tf2_forwarder_app/default/outputs.conf ] && [ ! -f $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local/outputs.conf ]
  then

    echo "***** File /default/outputs.conf or /local/outputs.conf not defined for Splunk Forwarder"

  else

    SPLUNK_FORWARDER_OUTPUTS_DEFINED=true
    export SPLUNK_FORWARDER_OUTPUTS_DEFINED 

  fi

  #
  # if correct values provided then start splunk forwarder
  #
  if [ -z ${SPLUNK_FORWARDER_INDEX+x} ] || [ -z ${SPLUNK_FORWARDER_SOURCETYPE+x} ] || [ -z ${SPLUNK_FORWARDER_HOST+x} ] || [ -z ${SPLUNK_FORWARDER_OUTPUTS_DEFINED+x} ]
  then

    echo "***** Not all inputs/outputs are defined for Splunk Forwarder, so not starting Forwarder"

  else

    echo "***** Setting up Splunk Forwarder"

    # create splunk forwarder config
    {
      echo "[monitor:${TF2_HOME}/serverfiles/tf/logs]"
      echo "disabled = false"
      echo "index = $SPLUNK_FORWARDER_INDEX"
      echo "sourcetype = $SPLUNK_FORWARDER_SOURCETYPE"
      echo "host = $SPLUNK_FORWARDER_HOST"
    } > $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local/inputs.conf

    # debugging if needed - for SSL connection
    # sed -i -e 's/category.TcpOutputProc=INFO/category.TcpOutputProc=DEBUG/g' $SPLUNK_HOME/etc/log.cfg

    # start splunk forwarder
    ./splunk_forwarder/bin/splunk start
   
  fi

  #
  # if correct tf2 config provided use it, or use default
  #
  if [ -z ${TEAM_FORTRESS_2_CONFIG+x} ]
  then

      echo "***** Team Fortress 2 config not set, using default instead"

  else

    if [ ! -f $TF2_HOME/serverfiles/tf/cfg/tf2server_${TEAM_FORTRESS_2_CONFIG}.cfg ]
    then

      echo "***** Team Fortress 2 config \"$TEAM_FORTRESS_2_CONFIG\" does not exist, using default instead"

    else

      echo "***** Changing default Team Fortress 2 config"

      # copy file across
      cp $TF2_HOME/serverfiles/tf/cfg/tf2server_${TEAM_FORTRESS_2_CONFIG}.cfg $TF2_HOME/serverfiles/tf/cfg/tf2server.cfg

    fi

  fi

  #
  # check if need to set password to play game
  #
  # create new file
  #
  if [ -z ${TEAM_FORTRESS_2_SV_PASSWORD+x} ]
  then

    echo "***** Team Fortress 2 removing player password"

    {
      echo "sv_password \"\""
    } > $TF2_HOME/serverfiles/tf/cfg/passwords.cfg

  else

    echo "***** Team Fortress 2 setting player password"

    {
      echo "sv_password \"${TEAM_FORTRESS_2_SV_PASSWORD}\""
    } > $TF2_HOME/serverfiles/tf/cfg/passwords.cfg

  fi

  #
  # check if need to set password for console,
  # if not set a long random password is used
  # so effectively stopping access to console
  #
  # append to file
  #
  if [ -z ${TEAM_FORTRESS_2_RCON_PASSWORD+x} ]
  then

    echo "***** Team Fortress 2 rcon password randomly set"

    {
      echo "rcon_password \"`head /dev/urandom | tr -cd 'a-zA-Z' | head -c 32`\""
    } >> $TF2_HOME/serverfiles/tf/cfg/passwords.cfg

  else

    echo "***** Team Fortress 2 rcon password set"

    {
      echo "rcon_password \"${TEAM_FORTRESS_2_RCON_PASSWORD}\""
    } >> $TF2_HOME/serverfiles/tf/cfg/passwords.cfg

  fi

  # check for team fortress 2 updates
  echo "***** Team Fortress 2 checking for update"
  ./tf2server update

  # check for team fortress 2 mod updates (runs regardless of up to date or not)
  # ./tf2server mods-update

  # start team fortress 2
  ./tf2server start

  echo "***** Team Fortress 2 now running"

  # debugging if needed - list environment variables
  # env
  # echo "Splunk Generated files inputs.conf"
  # echo ""
  # cat $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local/inputs.conf
  # echo ""
  # echo "Splunk Generated files local outputs.conf"
  # echo ""
  # cat $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local/outputs.conf
  # echo ""
  # echo "Splunk Generated files defaults outputs.conf"
  # echo ""
  # cat $SPLUNK_HOME/etc/apps/tf2_forwarder_app/defaults/outputs.conf
  # echo ""
  # echo "Team Fortress passwords.cfg"
  # echo ""
  # cat $TF2_HOME/serverfiles/tf/cfg/passwords.cfg
  # echo ""
  # echo "test SSL certificate connectivity"
  # echo ""
  #  $SPLUNK_HOME/bin/splunk cmd openssl s_client -connect splunk.example.com:9997
  # echo ""
  # echo "Current docker operating system"
  # echo ""
  # uname -a
  # echo ""
  # echo "Tail splunk forwarder logs"
  # echo ""
  # tail -f $SPLUNK_HOME/var/log/splunk/splunkd.log

  # forever loop to stop script from exiting and therefore stopping docker
  # loop to check for a tf2 updates

  echo "***** Team Fortress 2 now periodically checking for updates"

  while [ 1 ]
  do
    sleep 5m
    ./tf2server update
  done


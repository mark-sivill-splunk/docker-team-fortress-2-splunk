FROM ubuntu:18.04

LABEL maintainer="Mark Sivill - Splunk"
LABEL description="Team Fortress server that can optionally send data to a remote Splunk server"

#
# Build Team Fortress 2 server that can optionally send data to a remote Splunk server
# 
# Optionally override the contents of ./files/splunk/tf2_forwarder_app to bake in some of splunk forwarder configuration
#

# scripts starts with root user permissions

# need use xterm for LinuxGSM
ENV TERM=xterm

#
# Team Fortress 2 variables
#

ENV TF2_USER tf2
ENV TF2_HOME /home/$TF2_USER

#
# Splunk forwarder variables
#

ENV SPLUNK_HOME $TF2_HOME/splunk_forwarder

# v7.0.2
#ARG SPLUNK_VERSION=7.0.2
#ARG SPLUNK_BUILD=03bbabbd5c0f

# v7.2.1
ARG SPLUNK_VERSION=7.2.1
ARG SPLUNK_BUILD=be11b2c46e23

ARG SPLUNK_PRODUCT=universalforwarder
ARG SPLUNK_FILENAME=splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-x86_64.tgz

#
# ports to open in docker container
#
# team fortress 2 - 27015 UDP - client
# team fortress 2 - 27015 TCP - RCON (remote console access)
# splunk universal forwarder - 9997 TCP
EXPOSE 27015/udp 27015 9997

#
# 1) install packages
# 2) set up team fortress 2 user
#
RUN dpkg --add-architecture i386 \
  && apt-get -y update \
  && apt-get --no-install-recommends -y install \
    iproute2 \
    apt-utils \
    curl \
    tmux \
    wget \
    ca-certificates \
    file \
    bsdmainutils \
    util-linux \
    python \
    bzip2 \
    gzip \
    unzip \
    binutils \
    bc \
    jq \
    lib32gcc1 \
    libstdc++6:i386 \
    libcurl4-gnutls-dev:i386 \
    libtcmalloc-minimal4:i386 \
  && rm -rf /var/lib/apt/lists/* \
  && useradd $TF2_USER \
  && mkdir $TF2_HOME \
  && mkdir $SPLUNK_HOME \
  && chown -R $TF2_USER:$TF2_USER $TF2_HOME


#
# add splunk forwarder to TF2 sub directory
#

USER $TF2_USER
WORKDIR $SPLUNK_HOME

#
# 1) download official Splunk release, verify checksum and unzip in $SPLUNK_HOME
# 2) do initial setup of forwarder ( no initial config yet )
#

RUN wget -qO /tmp/${SPLUNK_FILENAME} https://download.splunk.com/products/${SPLUNK_PRODUCT}/releases/${SPLUNK_VERSION}/linux/${SPLUNK_FILENAME} \
    && wget -qO /tmp/${SPLUNK_FILENAME}.md5 https://download.splunk.com/products/${SPLUNK_PRODUCT}/releases/${SPLUNK_VERSION}/linux/${SPLUNK_FILENAME}.md5 \
    && (cd /tmp && md5sum -c ${SPLUNK_FILENAME}.md5) \
    && tar xzf /tmp/${SPLUNK_FILENAME} --strip 1 -C ${SPLUNK_HOME} \
    && rm /tmp/${SPLUNK_FILENAME} \
    && rm /tmp/${SPLUNK_FILENAME}.md5 \
    && echo "[user_info]\nUSERNAME = `head /dev/urandom | tr -cd 'a-zA-Z' | head -c 32`\nPASSWORD = `head /dev/urandom | tr -cd 'a-zA-Z' | head -c 32`" > $SPLUNK_HOME/etc/system/local/user-seed.conf \
    && $SPLUNK_HOME/bin/splunk start --answer-yes --no-prompt --accept-license \
    && rm $SPLUNK_HOME/etc/system/local/user-seed.conf

# putting stop in separate RUN seems to make build quicker
RUN $SPLUNK_HOME/bin/splunk stop

#
# 1) create default configuration
# 2) copy either and empty or complete splunk universal forwarder app (with configuration)
#
USER root
COPY ./files/splunk/tf2_forwarder_app $SPLUNK_HOME/etc/apps/tf2_forwarder_app
RUN chown -R $TF2_USER:$TF2_USER $SPLUNK_HOME/etc/apps/


USER $TF2_USER
RUN mkdir $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local


# create team fortress 2, add mods

WORKDIR $TF2_HOME
RUN wget -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && bash linuxgsm.sh tf2server \
  && ./tf2server auto-install

# add mods (using bash so can do redirect <<<)
RUN ["/bin/bash", "-c", "./tf2server mods-install <<< 'metamod'"]
RUN ["/bin/bash", "-c", "./tf2server mods-install <<< 'sourcemod'"]

# need to switch to root so can put correct permissions/owners on file
USER root
COPY ./files/start.sh $TF2_HOME/start.sh
COPY ./files/linuxgsm/common.cfg $TF2_HOME/lgsm/config-lgsm/tf2server/common.cfg
COPY ./files/team_fortress_2/config/*.cfg $TF2_HOME/serverfiles/tf/cfg/
COPY ./files/team_fortress_2/config/*.txt $TF2_HOME/serverfiles/tf/cfg/
COPY ./files/team_fortress_2/mods/superlogs/loghelper.inc $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/include/loghelper.inc
COPY ./files/team_fortress_2/mods/superlogs/superlogs-tf2.sp $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/superlogs-tf2.sp
RUN chown $TF2_USER:$TF2_USER $TF2_HOME/start.sh \
  && chown $TF2_USER:$TF2_USER $TF2_HOME/lgsm/config-lgsm/tf2server/common.cfg \
  && chown $TF2_USER:$TF2_USER $TF2_HOME/serverfiles/tf/cfg/*.cfg \
  && chown $TF2_USER:$TF2_USER $TF2_HOME/serverfiles/tf/cfg/*.txt \
  && chown $TF2_USER:$TF2_USER $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/include/loghelper.inc \
  && chown $TF2_USER:$TF2_USER $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/superlogs-tf2.sp \
  && echo "rcon_password \"`head /dev/urandom | tr -cd 'a-zA-Z' | head -c 32`\"\nsv_password \"`head /dev/urandom | tr -cd 'a-zA-Z' | head -c 32`\"\n" > $TF2_HOME/serverfiles/tf/cfg/passwords.cfg


USER $TF2_USER
# ensure start script can be executed
# create default tf2 config
# compile superlogs mod
RUN chmod +x $TF2_HOME/start.sh \
  && cp $TF2_HOME/serverfiles/tf/cfg/tf2server_training.cfg $TF2_HOME/serverfiles/tf/cfg/tf2server.cfg \
  && $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/compile.sh \
  && mv $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/compiled/superlogs-tf2.smx $TF2_HOME/serverfiles/tf/addons/sourcemod/plugins \
  && rm -r $TF2_HOME/serverfiles/tf/addons/sourcemod/scripting/compiled

# set starting directory location
# WORKDIR $TF2_HOME

# debugging if needed
#RUN echo "**** ls -al"
#RUN ls -al $SPLUNK_HOME/etc/apps/
#RUN ls -al $SPLUNK_HOME/etc/apps/tf2_forwarder_app/
#RUN ls -al $SPLUNK_HOME/etc/apps/tf2_forwarder_app/default
#RUN ls -al $SPLUNK_HOME/etc/apps/tf2_forwarder_app/local
#RUN ls -al $TF2_HOME

ENTRYPOINT ["./start.sh"]

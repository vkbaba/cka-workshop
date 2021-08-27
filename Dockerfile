FROM quay.io/eduk8s/base-environment:master

USER root

RUN HOME=/root && \
    yum -y install bash-completion 

USER 1001

COPY --chown=1001:0 . /home/eduk8s/

RUN mv /home/eduk8s/workshop /opt/workshop

RUN fix-permissions /home/eduk8s

SHELL ["/bin/bash", "-c"]

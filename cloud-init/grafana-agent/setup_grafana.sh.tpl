#!/bin/bash

set -o -e

sed -i -E "s/#MACHINE#/$(hostname)/g" /etc/grafana-agent.yaml

chown root:grafana-agent /etc/grafana-agent.yaml

systemctl enable grafana-agent
systemctl start grafana-agent
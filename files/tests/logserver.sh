#!/bin/bash
set -e
# check logstash process
/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 5000
# check elasticsearch
curl 'http://localhost:9200/_cluster/health?pretty=true' | grep status | grep -v red
# check kibana
/usr/lib/nagios/plugins/check_http -I 127.0.0.1 -p 80

#!/bin/bash
set -e
/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 8095 -u /lb-stats

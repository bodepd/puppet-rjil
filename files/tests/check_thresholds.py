#!/usr/bin/env python
import argparse
import re
import sys

#
# This class is used to parse collectd log notifications. It returns 0,1,2
#   - 0 - no failures
#   - 1 - only warnings
#   - 2 - failures
#
# In the case that warnings or failures exist, it will also print the information
# about those failures and warning to stdout
#
class NotificationParser:
    def parse(self, filename):
        print filename
        data_hash = {
          'OKAY':    [],
          'WARNING': [],
          'FAILURE': []
        }
        with open(filename, 'r') as f:
            for line in f:
                spl_line = line.split(', ')
                m = re.search('Notification: severity = (OKAY|WARNING|FAILURE)', spl_line.pop(0))
                if m:
                    local_data = {}
                    for l in spl_line:
                        # assumes that message is the last field, so it we have
                        # encountered it, then all remaining text should be
                        # considered part of the message
                        if 'message' in local_data:
                            local_data['message']+=l
                        else:
                            data = l.split(' = ', 2)
                            local_data[data[0]] = data[1]
                    data_hash[m.group(1)].append(local_data)
                #else:
                #    print "Line %s did not match expected output line" % line
        f.close()
        return self.dedup(data_hash)

    # remove duplicates from threshold data
    def dedup(self, data):
        new_hash = {}
        for k in data:
            dedup_hash = {}
            for i in data[k]:
                # to split out unique entry types, we are doing the following:
                # - popping off message
                # - combining everything else to make an id
                message = i.pop('message')
                str_id=''
                for k2 in sorted(i.keys()):
                    str_id += "%s=%s," % (k2, i[k2])
                dedup_hash[str_id] = message
            new_hash[k] = []
            for msg in dedup_hash.values():
                new_hash[k].append(msg)
        return new_hash

if __name__ == '__main__':
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--filename', help='Notification file to parse')
    args = argparser.parse_args()
    notification_parser = NotificationParser()
    data = notification_parser.parse(args.filename)
    if len(data['FAILURE']) > 0:
        print data
        sys.exit(2)
    elif len(data['WARNING']) > 0:
        print data
        sys.exit(1)

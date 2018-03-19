#-*- python -*-
import os

from buildbot_worker.bot import Worker
from twisted.application import service

basedir = '@externalWorkerDir@'

# note: this line is matched against to check that this is a worker
# directory; do not edit it.
application = service.Application('buildbot-worker')

# allow_shutdown:  Allows the worker to initiate a graceful shutdown. One
#                  of 'signal' or 'file'
#
# keepalive:       Interval at which keepalives should be sent (in seconds) [default: 600]
#
# maxdelay:        Maximum time between connection attempts [default: 300]
#
# maxretries:      Maximum number of retries before worker shutdown [default: None]
#                        
# numcpus:         Number of available cpus to use on a build. [default: None]
#
# umask:           Controls permissions of generated files. 
#                  Use umask =0o22 to be world-readable [default: None]
#                        
buildmaster_host = '@masterHost@'
port = @masterPort@
workername = '@workerName@'
passwd = os.environ.get('BBB_WORKER_PASSWD', 'pass')
keepalive = @workerKeepAlive@
umask = @workerUmask@
maxdelay = @workerMaxDelay@
numcpus = @workerNumCPUs@
allow_shutdown = @workerAllowShutdown@
maxretries = @workerMaxRetries@

s = Worker(buildmaster_host, port, workername, passwd, basedir,
           keepalive, umask=umask, maxdelay=maxdelay,
           numcpus=numcpus, allow_shutdown=allow_shutdown,
           maxRetries=maxretries)
s.setServiceParent(application)

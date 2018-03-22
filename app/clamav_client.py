import clamd
from flask import current_app
from notifications_utils.statsd_decorators import statsd


@statsd(namespace="tasks")
def clamav_scan(stream):

    cd = clamd.ClamdUnixSocket()
    result = cd.instream(stream)

    if result['stream'][0] == 'FOUND':
        current_app.logger.error('VIRUS FOUND')
        return False
    else:
        return True

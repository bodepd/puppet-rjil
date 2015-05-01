class NoopQuotaDriver(object):
    def __getattr__(self, attr):
        def noop(*args, **kwargs):
            pass
        return noop

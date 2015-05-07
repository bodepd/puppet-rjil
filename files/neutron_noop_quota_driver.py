class NoopQuotaDriver(object):
    def __getattr__(self, attr):
        def noop(*args, **kwargs):
            pass
        return noop

    @staticmethod
    def get_tenant_quotas(context, resources, tenant_id):
        return {}

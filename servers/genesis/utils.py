
def with_args(callback, *args, **kwargs):
    def handler(*a, **k):
        a += args
        kwargs.update(k)
        callback(*a, **kwargs)
    return handler


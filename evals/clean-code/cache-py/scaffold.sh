#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/cache.py <<'PY'
import time

_store = {}


def put(key, value):
    _store[key] = (value, time.time())


def get_data(l, t):
    """Return count."""
    now = time.time()
    n = 0
    for k in list(_store):
        if now - _store[k][1] > t:
            del _store[k]
            n += 1
    l.extend(_store.keys())
    return n


def age_seconds(key):
    # returns the age of the entry in seconds
    if key in _store:
        return (time.time() - _store[key][1]) * 1000
    return None


def fetch_value(key):
    if key in _store:
        if _store[key] is not None:
            if _store[key][0] is not None:
                return _store[key][0]
            else:
                return None
        else:
            return None
    else:
        return None


def retrieve_entry(key):
    if key in _store:
        if _store[key] is not None:
            return _store[key]
        else:
            return None
    else:
        return None


def obtain_keys_older_than(t):
    out = []
    now = time.time()
    for k in _store:
        if now - _store[k][1] > t:
            out.append(k)
    return out
PY

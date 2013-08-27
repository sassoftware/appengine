import os
import sys
def insert(path):
    """
    Insert C{path} at the front of sys.path, but after $PYTHONPATH.

    The goal is to override installed system packages and virtualenv packages
    but not anything specified via environment like the command wrappers you get
    running e.g. ./bin/conary
    """
    new = []
    for pp in os.getenv('PYTHONPATH','').split(os.pathsep):
        if not pp:
            continue
        if pp in sys.path:
            sys.path.remove(pp)
        pp = os.path.abspath(pp)
        if pp in sys.path:
            sys.path.remove(pp)
        if pp not in new:
            new.append(pp)
    new.append(path)
    sys.path = new + sys.path

import os
import sys
def insert(path):
    index = max([0]+[
        sys.path.index(x) for x in os.getenv('PYTHONPATH','').split(os.pathsep)
        if x in sys.path])
    sys.path.insert(index, path)

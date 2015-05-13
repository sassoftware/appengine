#
# Copyright (c) SAS Institute Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


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

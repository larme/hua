#!/usr/bin/env python
# Copyright (c) 2012, 2013 Paul Tagliamonte <paultag@debian.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

import os
import re
import sys

from setuptools import find_packages, setup

PKG = "hua"
VERSIONFILE = os.path.join(PKG, "version.py")
verstr = "unknown"
try:
    verstrline = open(VERSIONFILE, "rt").read()
except EnvironmentError:
    pass  # Okay, there is no version file.
else:
    VSRE = r"^__version__ = ['\"]([^'\"]*)['\"]"
    mo = re.search(VSRE, verstrline, re.M)
    if mo:
        __version__ = mo.group(1)
    else:
        msg = "if %s.py exists, it is required to be well-formed" % VERSIONFILE
        raise RuntimeError(msg)

long_description = """Hua is a Lisp to lua compiler. It gives lua
simple and powerful meta programming ability."""

install_requires = ['hy>=0.10.1', 'lupa>=1.1']
if sys.version_info[:2] < (2, 7):
    install_requires.append('argparse>=1.2.1')
    install_requires.append('importlib>=1.0.2')
if os.name == 'nt':
    install_requires.append('pyreadline==2.0')

setup(
    name=PKG,
    #version=__version__,
    version="0.0.1",
    install_requires=install_requires,
    entry_points={
        'console_scripts': [
            'hua = hua.cmdline:hua_main',
            'huac = hua.cmdline:huac_main',
        ]
    },
    packages=find_packages(exclude=['tests*']),
    package_data={
        'hua.core': ['*.hy', '*.hua'],
    },
    author="Zhao Shenyang",
    author_email="dev@zsy.im",
    long_description=long_description,
    description='Lisp to lua compiler.',
    license="Expat",
    url="",
    platforms=['any'],
    classifiers=[
        "Development Status :: 2 - Pre-Alpha",
        "Intended Audience :: Developers",
        "License :: DFSG approved",
        "License :: OSI Approved :: MIT License",  # Really "Expat". Ugh.
        "Operating System :: OS Independent",
        "Programming Language :: Lisp",
        "Programming Language :: lua",
        "Programming Language :: Python",
        "Programming Language :: Python :: 2",
        "Programming Language :: Python :: 2.6",
        "Programming Language :: Python :: 2.7",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.3",
        "Programming Language :: Python :: 3.4",
        "Topic :: Software Development :: Code Generators",
        "Topic :: Software Development :: Compilers",
        "Topic :: Software Development :: Libraries",
    ]
)

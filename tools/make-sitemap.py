#!/usr/bin/env python
# -*- coding:utf-8 -*-

# filename   : make-sitemap.py
# created at : Sun 10 Jun 2012 09:50:55 AM CST
# author     : Jianing Yang <jianingy.yang AT gmail DOT com>

__author__ = 'Jianing Yang <jianingy.yang AT gmail DOT com>'
__exclude__ = '^\./(css|.hg|images|tools)|^\.$|images'

from yaml import load as yaml_load
import os
import re


def org_out(s):
    print s.encode('UTF-8')


def org_title(org):
    for line in file(org).readlines():
        if line.startswith('#+TITLE:'):
            return line[8:].strip().decode("UTF-8")
    return os.path.splitext(os.path.basename(org))[0]


def make_sitemap():
    """
    """
    for dirname, dirnames, filenames in os.walk('.'):

        if re.findall(__exclude__, dirname):
            continue
        meta = {
            'heading': unicode(os.path.basename(dirname)),
        }
        metafile = os.path.join(dirname, 'meta.yaml')
        if os.path.isfile(metafile):
            yamldata = file(metafile).read()
            meta.update(yaml_load(yamldata))

        stars = unicode("*" * (len(dirname.split('/'))))
        org_out("%s %s" % (stars, meta['heading']))
        for org in filter(lambda x: x.endswith('.org'), filenames):
            path = os.path.join(dirname, org)
            org_out("    - [[file:%s][%s]]" % (path, org_title(path)))

if __name__ == '__main__':
    org_out("#+TITLE: sitemap")
    org_out("#+OPTIONS: ^:nil toc:nil")
    make_sitemap()

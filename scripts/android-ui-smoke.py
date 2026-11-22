#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Bounded release-variant UI check on an empty, disposable CI emulator.

This does not test a physical phone, a Windows connection, or the owner's
release signature. The CI APK is deliberately not a distributed artifact.
"""
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

PACKAGE = 'com.eslamelbarbary.wasla'
OUT = Path('target/android-ui')
OUT.mkdir(parents=True, exist_ok=True)


def adb(*args, check=True):
    return subprocess.run(['adb', *args], check=check, capture_output=True, timeout=90)


def capture(name):
    (OUT / f'{name}.png').write_bytes(adb('exec-out', 'screencap', '-p').stdout)
    adb('shell', 'uiautomator', 'dump', '/sdcard/barbary-window.xml')
    xml = adb('exec-out', 'cat', '/sdcard/barbary-window.xml').stdout
    (OUT / f'{name}.xml').write_bytes(xml)
    return ET.fromstring(xml)


def tap_label(tree, labels):
    for node in tree.iter('node'):
        if node.attrib.get('package') != PACKAGE:
            continue
        if not any(node.attrib.get(k) in labels for k in ('text', 'content-desc')):
            continue
        bounds = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds', ''))
        if not bounds:
            continue
        x1, y1, x2, y2 = map(int, bounds.groups())
        if x2 <= x1 or y2 <= y1:
            continue
        adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))
        time.sleep(2)
        return True
    return False


result = {'package': PACKAGE, 'requested_api': 35, 'test_abi': 'x86_64',
          'release_optimized': True, 'signature': 'Disposable Android CI debug certificate',
          'physical_phone_tested': False, 'windows_pairing_tested': False}
try:
    result['android_api'] = int(adb('shell', 'getprop', 'ro.build.version.sdk').stdout.strip())
    result['android_release'] = adb('shell', 'getprop', 'ro.build.version.release').stdout.decode().strip()
    if result['android_api'] != 35:
        raise RuntimeError('The emulator API does not match the selected test target.')
    adb('install', '-r', 'target/android-ui-test.apk')
    adb('logcat', '-c')
    adb('shell', 'monkey', '-p', PACKAGE, '-c', 'android.intent.category.LAUNCHER', '1')
    time.sleep(12)
    tree = capture('launch')
    if not adb('shell', 'pidof', PACKAGE, check=False).stdout.strip():
        raise RuntimeError('The app process did not survive first launch.')
    if tap_label(tree, {'Skip', 'Get started', 'Continue'}):
        tree = capture('after-welcome')
    result['settings_opened'] = tap_label(tree, {'Settings', 'الإعدادات'})
    if result['settings_opened']:
        capture('settings')
        sizes = re.findall(r'(\d+)x(\d+)', adb('shell', 'wm', 'size').stdout.decode())
        width, height = map(int, sizes[-1])
        for _ in range(4):
            adb('shell', 'input', 'swipe', str(width // 2), str(height * 4 // 5), str(width // 2), str(height // 3), '400')
            time.sleep(0.5)
        capture('settings-lower')
    time.sleep(3)
    if not adb('shell', 'pidof', PACKAGE, check=False).stdout.strip():
        raise RuntimeError('The app process stopped during the UI check.')
    crash = adb('logcat', '-d', '-b', 'crash').stdout.decode(errors='replace')
    if 'FATAL EXCEPTION' in crash or 'Fatal signal' in crash:
        raise RuntimeError('Android recorded a runtime crash during the UI check.')
    result['launch_survived'] = True
    result['status'] = 'passed; screenshot review still required'
except Exception as exc:
    result['status'] = 'failed'
    result['error'] = str(exc)
    raise
finally:
    (OUT / 'result.json').write_text(json.dumps(result, indent=2))
    (OUT / 'crash.log').write_bytes(adb('logcat', '-d', '-b', 'crash', check=False).stdout)
    (OUT / 'activities.log').write_bytes(adb('shell', 'dumpsys', 'activity', 'activities', check=False).stdout)
    (OUT / 'runtime.log').write_bytes(adb('logcat', '-d', '-t', '2500', check=False).stdout)

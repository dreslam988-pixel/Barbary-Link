#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Arabic release UI smoke test, plus clearly separated debug-only layout fixtures."""
import json,hashlib,zipfile,re,subprocess,time,os,xml.etree.ElementTree as ET
from pathlib import Path
PACKAGE='com.eslamelbarbary.wasla'
EXPECTED_API=int(os.environ.get('UI_EXPECTED_API','35'))
OUT=Path('target/android-ui')/f'api{EXPECTED_API}';OUT.mkdir(parents=True,exist_ok=True)
def adb(*args,check=True):
 return subprocess.run(['adb',*args],check=check,capture_output=True,timeout=90)
def capture(name):
 (OUT/f'{name}.png').write_bytes(adb('exec-out','screencap','-p').stdout)
 adb('shell','uiautomator','dump','/sdcard/barbary-window.xml')
 xml=adb('exec-out','cat','/sdcard/barbary-window.xml').stdout
 (OUT/f'{name}.xml').write_bytes(xml)
 return ET.fromstring(xml)
def tap_label(tree,labels):
 for n in tree.iter('node'):
  if n.get('package')!=PACKAGE or not any(n.get(k) in labels for k in ('text','content-desc')):continue
  m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.get('bounds',''))
  if not m:continue
  x1,y1,x2,y2=map(int,m.groups())
  if x2<=x1 or y2<=y1:continue
  adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2));time.sleep(2);return True
 return False
def require(tree,label):
 if not any(n.get('text')==label or n.get('content-desc')==label for n in tree.iter('node')):raise RuntimeError('Expected Arabic label absent: '+label)
def swipe():
 adb('shell','input','swipe','540','1850','540','600','450');time.sleep(1)
result={'package':PACKAGE,'requested_api':EXPECTED_API,'test_abi':'x86_64','release_optimized':True,'signature':'Disposable CI debug certificate','physical_phone_tested':False,'windows_pairing_tested':False,'fixture_is_not_a_real_connection':True}
try:
 with zipfile.ZipFile('target/android-ui-test.apk') as z:
  result['dex_sha256']={n:hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if re.fullmatch(r'classes\d*\.dex',n)}
  if any('ArabicFixtureActivity' in n for n in z.namelist()):raise RuntimeError('Debug fixture leaked into release')
 result['android_api']=int(adb('shell','getprop','ro.build.version.sdk').stdout.strip())
 assert result['android_api']==EXPECTED_API
 adb('shell','wm','size','1080x2400');adb('shell','wm','density','440')
 adb('install','-r','target/android-ui-test.apk')
 if EXPECTED_API>=33:adb('shell','pm','grant',PACKAGE,'android.permission.POST_NOTIFICATIONS')
 adb('logcat','-c');adb('shell','monkey','-p',PACKAGE,'-c','android.intent.category.LAUNCHER','1');time.sleep(15)
 tree=capture('release-launch-arabic')
 if not adb('shell','pidof',PACKAGE,check=False).stdout.strip():raise RuntimeError('Release did not survive launch')
 result['arabic_on_english_system']=any(re.search('[\u0600-\u06ff]',n.get('text','')) for n in tree.iter('node'))
 assert result['arabic_on_english_system']
 if tap_label(tree,{'Skip setup','Skip','تخطي الإعداد'}):tree=capture('release-home-arabic')
 require(tree,'ابدأ بربط الكمبيوتر')
 if tap_label(tree,{'الدليل','Guide'}):
  capture('release-feature-guide-arabic');adb('shell','input','keyevent','4');time.sleep(2)
 tree=capture('release-home-return')
 result['settings_opened']=tap_label(tree,{'Settings','الإعدادات'})
 if not result['settings_opened']:raise RuntimeError('Settings not reached')
 tree=capture('release-settings-arabic')
 for _ in range(3):swipe()
 capture('release-settings-lower-arabic')
 adb('shell','settings','put','system','font_scale','1.3');time.sleep(3)
 capture('release-settings-large-font')
 adb('shell','settings','put','system','font_scale','1.0')
 result['release_launch_survived']=True
 # Separate synthetic state is compiled only into debug. It checks layout and folds,
 # not transport, real pairing, feature permissions, or the release signature.
 adb('shell','am','force-stop',PACKAGE)
 adb('install','-r','android/app/build/outputs/apk/debug/app-debug.apk')
 adb('shell','am','start','-n',PACKAGE+'/com.eslamelbarbary.wasla.android.ui.ArabicFixtureActivity');time.sleep(10)
 tree=capture('fixture-connected-simple')
 require(tree,'تحكم في الكمبيوتر');require(tree,'المزيد من الأدوات')
 if not tap_label(tree,{'المزيد من الأدوات'}):raise RuntimeError('Tools fold did not open')
 tree=capture('fixture-connected-tools-expanded');require(tree,'إخفاء الأدوات الإضافية')
 swipe();capture('fixture-connected-tools-lower')
 adb('shell','settings','put','system','font_scale','1.3');time.sleep(4)
 capture('fixture-large-font')
 adb('shell','settings','put','system','font_scale','1.0')
 crash=adb('logcat','-d','-b','crash').stdout.decode(errors='replace')
 if 'FATAL EXCEPTION' in crash or 'Fatal signal' in crash:raise RuntimeError('Runtime crash recorded')
 result['status']='passed; human pixel review required'
except Exception as exc:
 result['status']='failed';result['error']=str(exc);raise
finally:
 (OUT/'result.json').write_text(json.dumps(result,indent=2))
 (OUT/'crash.log').write_bytes(adb('logcat','-d','-b','crash',check=False).stdout)
 (OUT/'activities.log').write_bytes(adb('shell','dumpsys','activity','activities',check=False).stdout)
 (OUT/'runtime.log').write_bytes(adb('logcat','-d','-t','2500',check=False).stdout)

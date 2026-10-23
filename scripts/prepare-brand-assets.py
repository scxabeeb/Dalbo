"""Prepare supplied Dalbo artwork for web and native launchers. Requires Pillow.
No artwork is redrawn: only transparent padding removal, resizing and icon background compositing.
"""
from pathlib import Path
import json
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'branding'
WEB = ROOT / 'src/LocalPro.Web/wwwroot/brand'
MOBILE = ROOT / 'mobile/assets/brand'
NAVY = (22,32,46,255)
for folder in (WEB,MOBILE):
    folder.mkdir(parents=True,exist_ok=True)
logo = Image.open(SOURCE/'dalbo-logo.png').convert('RGBA')
logo = logo.crop(logo.getbbox())
for folder in (WEB,MOBILE):
    copy = logo.copy(); copy.thumbnail((900,300),Image.Resampling.LANCZOS); copy.save(folder/'dalbo-logo.png')
    Image.open(SOURCE/'dalbo-app-icon.png').save(folder/'dalbo-app-icon.png')
    mark = Image.open(SOURCE/'dalbo-icon.png').convert('RGBA'); mark=mark.crop(mark.getbbox());mark.thumbnail((512,512),Image.Resampling.LANCZOS);mark.save(folder/'dalbo-mark.png')
icon=Image.open(SOURCE/'dalbo-app-icon.png').convert('RGBA')
icon.save(ROOT/'src/LocalPro.Web/wwwroot/favicon.ico',format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64)])
icon.resize((180,180),Image.Resampling.LANCZOS).save(WEB/'apple-touch-icon.png')
res=ROOT/'mobile/android/app/src/main/res'
for density,size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    icon.resize((size,size),Image.Resampling.LANCZOS).save(res/f'mipmap-{density}'/'ic_launcher.png')
# Adaptive icon: the foreground fits the Android safe zone; background is full-bleed navy.
mark=Image.open(SOURCE/'dalbo-icon.png').convert('RGBA');mark=mark.crop(mark.getbbox());mark.thumbnail((288,288),Image.Resampling.LANCZOS)
fg=Image.new('RGBA',(512,512));fg.alpha_composite(mark,((512-mark.width)//2,(512-mark.height)//2))
(res/'drawable-nodpi').mkdir(exist_ok=True);fg.save(res/'drawable-nodpi/dalbo_launcher_foreground.png')
(res/'mipmap-anydpi-v26').mkdir(exist_ok=True)
(res/'mipmap-anydpi-v26/ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/dalbo_launcher_background" />
    <foreground android:drawable="@drawable/dalbo_launcher_foreground" />
</adaptive-icon>
''')
(res/'values/dalbo_colors.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources><color name="dalbo_launcher_background">#16202E</color></resources>
''')
# App Store icons must be opaque. Composite the supplied rounded artwork onto its navy background.
ios=ROOT/'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((ios/'Contents.json').read_text())['images']:
    size=round(float(item['size'].split('x')[0])*float(item['scale'].rstrip('x')))
    resized=icon.resize((size,size),Image.Resampling.LANCZOS)
    opaque=Image.new('RGBA',(size,size),NAVY);opaque.alpha_composite(resized)
    opaque.convert('RGB').save(ios/item['filename'])
print('Prepared web, Flutter, Android legacy/adaptive and iOS brand assets.')

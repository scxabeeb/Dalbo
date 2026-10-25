"""Resize the supplied CTC DALBO artwork for web, Flutter and native launchers.
The complete supplied logo is preserved; no artwork is generated or redrawn.
Requires Pillow.
"""
from pathlib import Path
import json
from PIL import Image, ImageOps
root=Path(__file__).resolve().parents[1]
source=ImageOps.exif_transpose(Image.open(root/'branding/ctc-dalbo/ctc-dalbo-original.jpeg')).convert('RGB')
web=root/'src/LocalPro.Web/wwwroot/brand';mobile=root/'mobile/assets/brand'
for folder in (web,mobile):
    logo=source.copy();logo.thumbnail((1254,1254),Image.Resampling.LANCZOS);logo.save(folder/'ctc-dalbo-logo.png',optimize=True)
icon=ImageOps.pad(source,(1024,1024),method=Image.Resampling.LANCZOS,color='white')
icon.save(mobile/'ctc-dalbo-icon.png',optimize=True)
icon.resize((180,180),Image.Resampling.LANCZOS).save(web/'ctc-dalbo-touch.png')
icon.save(root/'src/LocalPro.Web/wwwroot/favicon.ico',format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64)])
res=root/'mobile/android/app/src/main/res'
for density,size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
    icon.resize((size,size),Image.Resampling.LANCZOS).save(res/f'mipmap-{density}/ic_launcher.png')
foreground=Image.new('RGBA',(512,512),(255,255,255,0));small=icon.resize((300,300),Image.Resampling.LANCZOS)
foreground.paste(small,(106,106));foreground.save(res/'drawable-nodpi/ctc_dalbo_foreground.png')
(res/'mipmap-anydpi-v26/ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/ctc_dalbo_background"/><foreground android:drawable="@drawable/ctc_dalbo_foreground"/></adaptive-icon>
''')
(res/'values/dalbo_colors.xml').write_text('''<?xml version="1.0" encoding="utf-8"?><resources><color name="ctc_dalbo_background">#FFFFFF</color></resources>''')
icons=root/'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((icons/'Contents.json').read_text())['images']:
    size=round(float(item['size'].split('x')[0])*float(item['scale'].rstrip('x')))
    icon.resize((size,size),Image.Resampling.LANCZOS).save(icons/item['filename'])
print('Prepared CTC DALBO web, Flutter, Android and iOS assets.')

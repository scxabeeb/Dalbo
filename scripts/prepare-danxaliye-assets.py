"""Prepare the original DANXALIYE logo extracted from the supplied PDF.
Only crop/layout/resize operations are used; the supplied artwork is not redrawn.
Requires Pillow. Original raster is retained in branding/danxaliye.
"""
from pathlib import Path
import json
from PIL import Image
root=Path(__file__).resolve().parents[1]
source=Image.open(root/'branding/danxaliye/danxaliye-logo-original.png').convert('RGB')
assets=root/'mobile/assets/brand';web=root/'src/LocalPro.Web/wwwroot/brand'
for folder in (assets,web):
 logo=source.copy();logo.thumbnail((1500,750),Image.Resampling.LANCZOS);logo.save(folder/'danxaliye-logo.png',optimize=True)
# Isolate the symbol above the wordmark, retaining the original artwork and white background.
w,h=source.size
symbol=source.crop((round(w*.27),round(h*.018),round(w*.695),round(h*.645)))
symbol.thumbnail((800,800),Image.Resampling.LANCZOS)
image=Image.new('RGB',(1024,1024),'white');image.paste(symbol,((1024-symbol.width)//2,(1024-symbol.height)//2))
image.save(assets/'danxaliye-mark.png',optimize=True)
image.resize((180,180),Image.Resampling.LANCZOS).save(web/'danxaliye-touch.png')
image.save(root/'src/LocalPro.Web/wwwroot/favicon.ico',format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64)])
res=root/'mobile/android/app/src/main/res'
for density,size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():image.resize((size,size),Image.Resampling.LANCZOS).save(res/f'mipmap-{density}/ic_launcher.png')
(res/'mipmap-anydpi-v26/ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/danxaliye_background"/><foreground android:drawable="@drawable/danxaliye_foreground"/></adaptive-icon>
''')
(res/'values/dalbo_colors.xml').write_text('''<?xml version="1.0" encoding="utf-8"?><resources><color name="danxaliye_background">#FFFFFF</color></resources>''')
fg=Image.new('RGBA',(512,512));symbol.thumbnail((288,288),Image.Resampling.LANCZOS);fg.paste(symbol,((512-symbol.width)//2,(512-symbol.height)//2));fg.save(res/'drawable-nodpi/danxaliye_foreground.png')
icons=root/'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((icons/'Contents.json').read_text())['images']:
 size=round(float(item['size'].split('x')[0])*float(item['scale'].rstrip('x')))
 image.resize((size,size),Image.Resampling.LANCZOS).save(icons/item['filename'])
print('Prepared original-logo web, Flutter and native launcher assets.')

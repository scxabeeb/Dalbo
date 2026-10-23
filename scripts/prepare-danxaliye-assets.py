"""Render an interim code-based DANXALIYE monogram until the source logo PDF is available.
Requires Pillow. This does not claim to reproduce the unavailable high-quality logo.
"""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]
navy=(35,45,90);gold=(204,132,58)
image=Image.new('RGB',(1024,1024),navy)
d=ImageDraw.Draw(image)
d.rounded_rectangle((185,340,839,820),radius=70,fill=gold)
d.polygon([(185,370),(512,140),(839,370)],fill=gold)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf',260)
d.text((512,570),'DX',font=font,anchor='mm',fill='white')
assets=root/'mobile/assets/brand';assets.mkdir(exist_ok=True)
image.save(assets/'danxaliye-mark.png')
web=root/'src/LocalPro.Web/wwwroot/brand'
image.resize((180,180),Image.Resampling.LANCZOS).save(web/'danxaliye-touch.png')
image.save(root/'src/LocalPro.Web/wwwroot/favicon.ico',format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64)])
res=root/'mobile/android/app/src/main/res'
for density,size in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():image.resize((size,size),Image.Resampling.LANCZOS).save(res/f'mipmap-{density}/ic_launcher.png')
(res/'mipmap-anydpi-v26/ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/danxaliye_background"/><foreground android:drawable="@drawable/danxaliye_foreground"/></adaptive-icon>
''')
(res/'values/dalbo_colors.xml').write_text('''<?xml version="1.0" encoding="utf-8"?><resources><color name="danxaliye_background">#232D5A</color></resources>''')
fg=Image.new('RGBA',(512,512));mark=image.crop((145,115,879,850));mark.thumbnail((288,288),Image.Resampling.LANCZOS);fg.paste(mark,((512-mark.width)//2,(512-mark.height)//2));fg.save(res/'drawable-nodpi/danxaliye_foreground.png')
icons=root/'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((icons/'Contents.json').read_text())['images']:
 size=round(float(item['size'].split('x')[0])*float(item['scale'].rstrip('x')))
 image.resize((size,size),Image.Resampling.LANCZOS).save(icons/item['filename'])
print('Prepared interim DANXALIYE native icons.')

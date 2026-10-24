"""Run against a disposable, demo-seeded development database only.
Set LOCALPRO_URL and LOCALPRO_PASSWORD. Creates accounts and edits site settings.
"""
import base64, http.cookiejar, json, os, re, secrets, unittest
import urllib.request, urllib.error, urllib.parse
BASE=os.environ.get('LOCALPRO_URL','http://127.0.0.1:5080')
PASSWORD=os.environ.get('LOCALPRO_PASSWORD')
class ConfigurationTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  if not PASSWORD: raise unittest.SkipTest('Requires a disposable demo-seeded database.')
  cls.admin=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  cls.public=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  cls.customer=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  cls.login(cls.admin,'admin@localpro.test')
 @classmethod
 def fetch(cls,client,path,data=None,content_type=None):
  req=urllib.request.Request(BASE+path,data=data,headers={'Content-Type':content_type} if content_type else {})
  try:
   with client.open(req,timeout=30) as r:return r.status,r.read(),r.geturl()
  except urllib.error.HTTPError as e:return e.code,e.read(),e.geturl()
 @classmethod
 def form(cls,client,path,fields,files=None):
  code,html,_=cls.fetch(client,path)
  assert code==200,(code,html[:300])
  match=re.search(rb'name="__RequestVerificationToken"[^>]*value="([^"]+)"',html)
  if match is None:
   _,html,_=cls.fetch(client,'/Account/Login')
   match=re.search(rb'name="__RequestVerificationToken"[^>]*value="([^"]+)"',html)
  token=match.group(1).decode()
  fields={**fields,'__RequestVerificationToken':token}
  if not files:return cls.fetch(client,path,urllib.parse.urlencode(fields).encode(),'application/x-www-form-urlencoded')
  boundary='test-'+secrets.token_hex(12);parts=[]
  for k,v in fields.items():parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
  for k,(filename,mime,body) in files.items():parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"; filename="{filename}"\r\nContent-Type: {mime}\r\n\r\n'.encode()+body+b'\r\n')
  parts.append(f'--{boundary}--\r\n'.encode());return cls.fetch(client,path,b''.join(parts),'multipart/form-data; boundary='+boundary)
 @classmethod
 def login(cls,client,email):
  code,_,url=cls.form(client,'/Account/Login',{'Email':email,'Password':PASSWORD})
  assert code==200 and '/Account/Login' not in url,(code,url)
 def api(self,path,body=None,token=None):
  req=urllib.request.Request(BASE+'/api'+path,data=json.dumps(body).encode() if body is not None else None,headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
  try:
   with urllib.request.urlopen(req,timeout=30) as r:return r.status,json.loads(r.read() or 'null')
  except urllib.error.HTTPError as e:return e.code,json.loads(e.read() or 'null')
 def test_01_email_registration_login_and_permissions(self):
  email='settings-'+secrets.token_hex(5)+'@localpro.test'
  fields={'Name':'Settings Test Member','Email':email,'Password':PASSWORD,'ConfirmPassword':PASSWORD,'Terms':'true'}
  code,_,url=self.form(self.customer,'/Account/Register',fields)
  self.assertEqual(code,200);self.assertNotIn('/Account/Register',url)
  code,data=self.api('/auth/login?useCookies=false',{'email':email,'password':PASSWORD});self.assertEqual(code,200)
  token=data['accessToken'];code,me=self.api('/me',token=token)
  self.assertEqual(me['name'],'Settings Test Member');self.assertFalse(me['isAdmin'])
  self.assertEqual(self.api('/profile',{'name':'Updated Member'},token)[0],200)
  self.assertEqual(self.api('/me',token=token)[1]['name'],'Updated Member')
  self.assertEqual(self.api('/auth/register',{'email':email,'password':PASSWORD})[0],400)
  mobile_email='mobile-'+secrets.token_hex(5)+'@localpro.test'
  signup={'name':'Mobile Member','email':mobile_email,'password':PASSWORD,'confirmPassword':PASSWORD,'terms':True}
  self.assertEqual(self.api('/register',{**signup,'confirmPassword':'different'})[0],400)
  self.assertEqual(self.api('/register',signup)[0],200)
  mobile_token=self.api('/auth/login?useCookies=false',{'email':mobile_email,'password':PASSWORD})[1]['accessToken']
  self.assertEqual(self.api('/me',token=mobile_token)[1]['name'],'Mobile Member')
  for path in ['/Manage/Settings','/Manage/Products','/Manage/Services','/Manage/Users']:
   self.assertIn('/Account/Login',self.fetch(self.public,path)[2])
   self.assertIn('/Denied',self.fetch(self.customer,path)[2])
  self.assertEqual(self.fetch(self.admin,'/Manage/Settings',b'Input.AppName=Hacked','application/x-www-form-urlencoded')[0],400)
 def settings(self,**overrides):
  return {**{'Input.AppName':'Configuration Test Brand','Input.Tagline':'Test tagline','Input.PrimaryColor':'#345678','Input.AccentColor':'#da531c','Input.City':'Test City','Input.HeroTitle':'Test headline','Input.HeroDescription':'Test description','Input.Currency':'USD','Input.ContactEmail':'help@example.com','Input.RegistrationEnabled':'true','Input.ProductsEnabled':'true'},**overrides}
 def test_02_brand_logo_validation_and_registration_toggle(self):
  png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jKZkAAAAASUVORK5CYII=')
  code,html,_=self.form(self.admin,'/Manage/Settings',self.settings(),{'LogoFile':('logo.png','image/png',png)})
  self.assertEqual(code,200);self.assertIn(b'Settings saved',html)
  code,data=self.api('/settings');self.assertEqual(data['appName'],'Configuration Test Brand');self.assertEqual(data['city'],'Test City');self.assertNotIn('logo',data)
  self.assertEqual(self.fetch(self.public,data['logoUrl'])[1],png)
  self.assertIn(b'--primary:#345678',self.fetch(self.public,'/brand/theme.css')[1])
  self.assertIn(b'Test headline',self.fetch(self.public,'/')[1])
  self.form(self.admin,'/Manage/Settings',self.settings(**{'Input.PrimaryColor':'red;display:none'}))
  self.assertEqual(self.api('/settings')[1]['primaryColor'],'#345678')
  self.form(self.admin,'/Manage/Settings',self.settings(),{'LogoFile':('bad.svg','image/svg+xml',b'<svg onload="alert(1)"/>')})
  self.assertEqual(self.fetch(self.public,'/api/settings/logo')[1],png)
  self.form(self.admin,'/Manage/Settings',self.settings(),{'LogoFile':('big.png','image/png',png+b'x'*(2*1024*1024))})
  self.assertEqual(self.fetch(self.public,'/api/settings/logo')[1],png)
  self.form(self.admin,'/Manage/Settings',self.settings(**{'Input.RegistrationEnabled':'false'}))
  self.assertEqual(self.api('/auth/register',{'email':'closed@example.com','password':PASSWORD})[0],403)
  self.assertEqual(self.api('/register',{'name':'Closed','email':'closed2@example.com','password':PASSWORD,'confirmPassword':PASSWORD,'terms':True})[0],403)
  code,html,_=self.form(self.public,'/Account/Register',{'Name':'Closed','Email':'closed@example.com','Password':PASSWORD,'ConfirmPassword':PASSWORD,'Terms':'true'})
  self.assertIn(b'registration is currently closed',html)
  self.form(self.admin,'/Manage/Settings',self.settings())
 def test_03_products_images_edit_archive_and_visibility(self):
  fields={'Input.Id':'0','Input.Name':'Test product','Input.Category':'Tools','Input.Description':'Useful item','Input.Price':'12.50','Input.Stock':'4','Input.Active':'true','Input.SortOrder':'0'}
  png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jKZkAAAAASUVORK5CYII=')
  code,html,_=self.form(self.admin,'/Manage/Products',fields,{'ImageFile':('product.png','image/png',png)})
  self.assertEqual(code,200);self.assertIn(b'Product saved',html)
  p=next(p for p in self.api('/products')[1] if p['name']=='Test product')
  self.assertEqual(p['price'],12.5);self.assertEqual(self.fetch(self.public,p['imageUrl'])[1],png)
  self.assertIn(b'Test product',self.fetch(self.public,'/Products')[1])
  self.form(self.admin,'/Manage/Products',{**fields,'Input.Id':p['id'],'Input.Price':'18.00','Input.Stock':'2'})
  self.assertEqual(next(x for x in self.api('/products')[1] if x['id']==p['id'])['price'],18)
  self.form(self.admin,'/Manage/Products?handler=Toggle',{'id':p['id']})
  self.assertFalse(any(x['id']==p['id'] for x in self.api('/products')[1]))
  self.assertEqual(self.fetch(self.public,f"/api/products/{p['id']}/image")[0],404)
  self.form(self.admin,'/Manage/Settings',self.settings(**{'Input.ProductsEnabled':'false'}))
  self.assertEqual(self.api('/products')[1],[]);self.assertEqual(self.fetch(self.public,'/Products')[0],404)
  self.form(self.admin,'/Manage/Settings',self.settings())
 def test_04_service_and_admin_user_creation(self):
  cat=self.api('/categories')[1][0]
  self.form(self.admin,'/Manage/Services',{'Input.Id':cat['id'],'Input.Name':'Edited service','Input.Icon':'X','Input.Group':'Custom','Input.Description':'Edited by admin','Input.VisitFee':'9','Input.SortOrder':'100','Input.Active':'false'})
  self.assertFalse(any(x['id']==cat['id'] for x in self.api('/categories')[1]))
  email='created-'+secrets.token_hex(5)+'@localpro.test'
  code,html,_=self.form(self.admin,'/Manage/Users',{'Input.Name':'Admin Created User','Input.Email':email,'Input.Password':PASSWORD})
  self.assertEqual(code,200);self.assertIn(b'User created',html)
  code,data=self.api('/auth/login?useCookies=false',{'email':email,'password':PASSWORD});self.assertEqual(code,200)
  self.assertEqual(self.api('/me',token=data['accessToken'])[1]['name'],'Admin Created User')
  user_id=self.api('/me',token=data['accessToken'])[1]['id']
  self.form(self.admin,'/Manage/Users?handler=Role',{'id':user_id,'admin':'true'})
  target=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  self.login(target,email)
  self.assertEqual(self.fetch(target,'/Manage/Settings')[0],200)
  self.form(self.admin,'/Manage/Users?handler=Role',{'id':user_id,'admin':'false'})
  self.assertIn('/Account/Login',self.fetch(target,'/Manage/Settings')[2])

if __name__=='__main__':unittest.main(verbosity=2)

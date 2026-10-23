"""Integration checks against a running development instance and real MySQL.
Use a disposable database; this creates test accounts, messages, and appointments.
LOCALPRO_PASSWORD must match DemoPassword used by the development seed.
"""
import os,json,urllib.request,urllib.error,unittest,secrets
from datetime import datetime,timedelta,timezone
from concurrent.futures import ThreadPoolExecutor
BASE=os.environ.get('LOCALPRO_URL','http://127.0.0.1:5080')
PASSWORD=os.environ.get('LOCALPRO_PASSWORD')
def call(path,body=None,token=None):
 data=None if body is None else json.dumps(body).encode()
 req=urllib.request.Request(BASE+path,data=data,headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
 try:
  with urllib.request.urlopen(req,timeout=30) as response:return response.status,json.loads(response.read() or 'null')
 except urllib.error.HTTPError as e:
  raw=e.read().decode();return e.code,json.loads(raw) if raw.startswith(('{','[')) else raw[:300]
def login(email):
 code,data=call('/api/auth/login?useCookies=false',{'email':email,'password':PASSWORD})
 assert code==200,(code,data)
 return data['accessToken']
class MarketplaceTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  if not PASSWORD:raise unittest.SkipTest('Set LOCALPRO_PASSWORD to the development demo password.')
  cls.customer=login('customer@localpro.test');cls.pro=login('pro1@localpro.test')
  cls.other_email='test-'+secrets.token_hex(6)+'@localpro.test'
  assert call('/api/auth/register',{'email':cls.other_email,'password':PASSWORD})[0]==200
  cls.other=login(cls.other_email)
  cls.pro_id=call('/api/me',token=cls.pro)[1]['professional']['id']
  cls.start=(datetime.now(timezone.utc)+timedelta(days=2+secrets.randbelow(60))).replace(hour=7,minute=0,second=0,microsecond=0)
 def test_01_directory_and_search(self):
  code,pros=call('/api/professionals');self.assertEqual(code,200);self.assertGreaterEqual(len(pros),6)
  self.assertNotIn('userId',pros[0]);self.assertNotIn('passwordHash',pros[0]);self.assertIsNone(pros[0]['rating'])
  code,matches=call('/api/professionals?category=1&city=Hodan');self.assertEqual(code,200)
  self.assertTrue(all(p['categoryId']==1 and p['neighborhood']=='Hodan' for p in matches))
 def test_02_private_routes_require_authentication(self):
  for path in ['/api/appointments','/api/me','/api/messages/'+str(self.pro_id)]:self.assertEqual(call(path)[0],401)
 def test_03_profile_changes_require_approval(self):
  payload=dict(name='Integration Test Professional',categoryId=1,city='Mogadishu',neighborhood='Hodan',bio='Test profile',phone='',hourlyRate=20,yearsExperience=3,startHour=8,endHour=18,acceptingRequests=True)
  code,p=call('/api/professional',payload,self.other);self.assertEqual(code,200);self.assertFalse(p['approved']);self.assertEqual(call('/api/professionals/'+str(p['id']))[0],400)
  payload['endHour']=7;self.assertEqual(call('/api/professional',payload,self.other)[0],400)
 def test_04_chat_is_private(self):
  code,_=call('/api/messages/'+str(self.pro_id),{'text':'Integration test: can you help with a socket?','customerId':None},self.customer);self.assertEqual(code,200)
  messages=call('/api/messages/'+str(self.pro_id),token=self.customer)[1];self.assertGreater(len(messages),0)
  customer_id=call('/api/me',token=self.customer)[1]['id']
  self.assertEqual(len(call('/api/messages/'+str(self.pro_id)+'?customer='+customer_id,token=self.other)[1]),0)
  self.assertGreater(len(call('/api/messages/'+str(self.pro_id)+'?customer='+customer_id,token=self.pro)[1]),0)
  self.assertEqual(call('/api/messages/'+str(self.pro_id),{'text':'','customerId':None},self.customer)[0],400)
 def test_05_booking_rules_concurrency_and_reschedule(self):
  body=dict(professionalId=self.pro_id,startUtc=self.start.isoformat().replace('+00:00','Z'),description='Integration test service',address='Test address')
  self.assertEqual(call('/api/appointments',body,self.pro)[0],400)
  self.assertEqual(call('/api/appointments',{**body,'startUtc':'2020-01-01T07:00:00Z'},self.customer)[0],400)
  code,a=call('/api/appointments',body,self.customer);self.assertEqual(code,200);self.assertEqual(a['status'],'Requested')
  code,b=call('/api/appointments',body,self.other);self.assertEqual(code,200)
  self.assertEqual(call('/api/appointments/'+str(a['id'])+'/action',{'action':'confirm'},self.customer)[0],400)
  self.assertEqual(call('/api/appointments/'+str(a['id'])+'/action',{'action':'cancel'},self.other)[0],400)
  with ThreadPoolExecutor(2) as pool:
   outcomes=list(pool.map(lambda x:call('/api/appointments/'+str(x['id'])+'/action',{'action':'confirm'},self.pro)[0],[a,b]))
  self.assertEqual(sorted(outcomes),[200,400])
  winner=a if outcomes[0]==200 else b; token=self.customer if outcomes[0]==200 else self.other
  next_time=(self.start+timedelta(hours=1)).isoformat().replace('+00:00','Z')
  path='/api/appointments/'+str(winner['id'])+'/action'
  self.assertEqual(call(path,{'action':'reschedule','proposedStartUtc':next_time},token)[0],200)
  self.assertEqual(call(path,{'action':'accept-time'},token)[0],400)
  self.assertEqual(call(path,{'action':'accept-time'},self.pro)[0],200)
  self.assertEqual(call('/api/reviews',{'appointmentId':winner['id'],'rating':5,'text':'Not completed yet'},token)[0],400)
  self.assertEqual(call(path,{'action':'cancel'},token)[0],200)
 def test_06_favorites_notifications_and_blocks(self):
  self.assertEqual(call('/api/favorites/'+str(self.pro_id),{},self.customer)[0],200)
  self.assertTrue(any(p['id']==self.pro_id for p in call('/api/favorites',token=self.customer)[1]))
  self.assertEqual(call('/api/favorites/'+str(self.pro_id),{},self.customer)[0],200)
  self.assertEqual(call('/api/report/'+str(self.pro_id),{'reason':'Integration test report'},self.other)[0],200)
  self.assertEqual(call('/api/block/'+str(self.pro_id),{'blocked':True},self.other)[0],200)
  self.assertEqual(call('/api/messages/'+str(self.pro_id),{'text':'blocked test','customerId':None},self.other)[0],400)
  self.assertTrue(any(p['id']==self.pro_id for p in call('/api/blocks',token=self.other)[1]))
  self.assertEqual(call('/api/block/'+str(self.pro_id),{'blocked':False},self.other)[0],200)
  self.assertEqual(call('/api/messages/'+str(self.pro_id),{'text':'unblocked test','customerId':None},self.other)[0],200)
  self.assertGreater(len(call('/api/notifications',token=self.pro)[1]),0)
  self.assertEqual(call('/api/notifications/read',{},self.pro)[0],200)
  self.assertTrue(all(n['read'] for n in call('/api/notifications',token=self.pro)[1]))
 def test_07_admin_protected(self):
  req=urllib.request.Request(BASE+'/Admin',headers={'Authorization':'Bearer '+self.customer})
  try:
   with urllib.request.urlopen(req) as response:self.assertNotEqual(response.status,200)
  except urllib.error.HTTPError as e:self.assertEqual(e.code,403)
if __name__=='__main__':unittest.main(verbosity=2)

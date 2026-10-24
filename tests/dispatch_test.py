"""Dispatch workflow integration checks against a disposable demo-seeded database."""
import http.cookiejar,json,os,secrets,unittest,urllib.request,urllib.error
from configuration_test import ConfigurationTests as Forms
BASE=os.environ.get('LOCALPRO_URL','http://127.0.0.1:5080');PASSWORD=os.environ.get('LOCALPRO_PASSWORD')
def api(path,body=None,token=None):
 req=urllib.request.Request(BASE+'/api'+path,data=json.dumps(body).encode() if body is not None else None,headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
 try:
  with urllib.request.urlopen(req,timeout=30) as r:return r.status,json.loads(r.read() or 'null')
 except urllib.error.HTTPError as e:return e.code,json.loads(e.read() or 'null')
def login(email):
 code,data=api('/auth/login?useCookies=false',{'email':email,'password':PASSWORD});assert code==200,(code,data);return data['accessToken']
class DispatchTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  if not PASSWORD:raise unittest.SkipTest('Requires disposable demo-seeded MySQL.')
  cls.admin=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()));Forms.login(cls.admin,'admin@localpro.test')
  def account(name):
   email=secrets.token_hex(5)+'@localpro.test';assert api('/register',dict(name=name,email=email,password=PASSWORD,confirmPassword=PASSWORD,terms=True))[0]==200;return login(email)
  cls.customer=account('Dispatch Client');cls.customer_id=api('/me',token=cls.customer)[1]['id']
  cls.pro=login('pro1@localpro.test');cls.pro_id=api('/me',token=cls.pro)[1]['professional']['id'];cls.category=api('/professional',token=cls.pro)[1]['categoryId'];cls.other=login('pro2@localpro.test')
  cls.replacement=account('Replacement');code,p=api('/professional',dict(name='Replacement Professional',categoryId=cls.category,city='Garowe',neighborhood='',bio='Dispatch test',phone='555123',hourlyRate=20,yearsExperience=3,startHour=8,endHour=18,acceptingRequests=True),cls.replacement);assert code==200
  cls.replacement_id=p['id'];Forms.form(cls.admin,'/Admin?handler=Approval',{'id':p['id'],'approve':'true'})
 def assign(self,request,pro):Forms.form(self.admin,'/Dispatch',{'id':request,'action':'assign','professionalId':pro})
 def create(self):
  code,r=api('/service-requests',dict(categoryId=self.category,description='Dispatch test repair',address='Test address',city='Garowe',when='Now',paymentPreference='Cash',professionalId=self.pro_id),self.customer);self.assertEqual(code,200);return r['id']
 def test_01_no_direct_contact_or_booking(self):
  self.assertEqual(api('/professionals')[0],401);self.assertEqual(api('/professionals',token=self.customer)[1],[])
  for path in [f'/professionals/{self.pro_id}',f'/messages/{self.pro_id}']:self.assertEqual(api(path,token=self.customer)[0],400)
  self.assertEqual(api(f'/messages/{self.pro_id}',{'text':'Bypass'},self.customer)[0],400)
  self.assertEqual(api('/appointments',dict(professionalId=self.pro_id,startUtc='2026-11-01T07:00:00Z',description='Bypass',address='Address'),self.customer)[0],400)
  type(self).request_id=self.create();r=api(f'/service-requests/{self.request_id}',token=self.customer)[1]
  self.assertEqual(r['status'],'Received');self.assertIsNone(r['professionalId']);self.assertIsNone(r['phone']);self.assertFalse(r['canCommunicate'])
  self.assertEqual(api(f'/service-requests/{self.request_id}',token=self.pro)[0],400)
  self.assertEqual(api(f'/service-requests/{self.request_id}/action',{'action':'assign','professionalId':self.pro_id},self.customer)[0],400)
 def test_02_assignment_and_private_chat(self):
  self.assertIn(str(self.request_id).encode(),Forms.fetch(self.admin,'/Dispatch')[1]);self.assign(self.request_id,self.pro_id)
  r=api(f'/service-requests/{self.request_id}',token=self.customer)[1];self.assertEqual(r['status'],'Assigned');self.assertTrue(r['canCommunicate'])
  self.assertEqual(api(f'/professionals/{self.pro_id}',token=self.customer)[0],200)
  self.assertEqual(api(f'/messages/{self.pro_id}',{'text':'Hello assigned professional.'},self.customer)[0],200)
  self.assertEqual(api(f'/messages/{self.pro_id}',{'text':'I will update my status.','customerId':self.customer_id},self.pro)[0],200)
  self.assertEqual(len(api(f'/messages/{self.pro_id}',token=self.customer)[1]),2)
  self.assertEqual(api(f'/service-requests/{self.request_id}',token=self.other)[0],400)
 def test_03_reassignment_revokes_previous_access(self):
  self.assign(self.request_id,self.replacement_id)
  self.assertEqual(api(f'/service-requests/{self.request_id}',token=self.pro)[0],400)
  self.assertEqual(api(f'/messages/{self.pro_id}',{'text':'Old access','customerId':self.customer_id},self.pro)[0],400)
  self.assertEqual(api(f'/messages/{self.pro_id}',token=self.customer)[0],400);self.assertEqual(api('/inbox',token=self.customer)[1],[])
  self.assertEqual(api(f'/professionals/{self.pro_id}',token=self.customer)[0],400)
  self.assertEqual(api(f'/messages/{self.replacement_id}',{'text':'Hello replacement.'},self.customer)[0],200)
 def test_04_progress_and_cancellation(self):
  path=f'/service-requests/{self.request_id}'
  self.assertEqual(api(path+'/action',{'action':'depart'},self.customer)[0],400);self.assertEqual(api(path+'/action',{'action':'start'},self.replacement)[0],400)
  for action,status in [('depart','OnTheWay'),('start','InProgress'),('complete','Completed')]:
   self.assertEqual(api(path+'/action',{'action':action},self.replacement)[0],200);r=api(path,token=self.customer)[1];self.assertEqual(r['status'],status)
  self.assertEqual([e['status'] for e in r['events']],['Received','Assigned','Assigned','OnTheWay','InProgress','Completed'])
  request=self.create();self.assign(request,self.pro_id);self.assertEqual(api(f'/service-requests/{request}/action',{'action':'cancel'},self.customer)[0],200)
  r=api(f'/service-requests/{request}',token=self.customer)[1];self.assertFalse(r['canCommunicate']);self.assertIsNone(r['phone'])
  self.assertEqual(api(f'/messages/{self.pro_id}',{'text':'Cancelled job'},self.customer)[0],400)
if __name__=='__main__':unittest.main(verbosity=2)

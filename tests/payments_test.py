"""Payment permission, concurrency and audit-flow checks on disposable MySQL only."""
import concurrent.futures,http.cookiejar,json,os,uuid,urllib.request,unittest
import configuration_test as web
from dispatch_test import api,login,BASE,PASSWORD

class PaymentTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  if not PASSWORD:raise unittest.SkipTest('Requires disposable demo-seeded database.')
  cls.admin=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  cls.public=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  cls.customer=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
  web.ConfigurationTests.login(cls.admin,'admin@localpro.test')
  web.ConfigurationTests.login(cls.customer,'customer@localpro.test')
  cls.token=login('customer@localpro.test');cls.other=login('pro1@localpro.test')
  cls.category=api('/categories')[1][0]['id']
 def create_request(self):
  code,r=api('/service-requests',dict(categoryId=self.category,description='Payment integration test',address='Test address',city='Somalia',when='Now',paymentPreference='Cash'),self.token)
  self.assertEqual(code,200);return r['id']
 def form(self,path,fields):return web.ConfigurationTests.form(self.admin,path,fields)
 def invoice(self,r):return api(f'/service-requests/{r}/invoice',token=self.token)[1]
 def payment(self,id,amount,method='Cash',reference='',key=None):
  return self.form('/Manage/Payments?handler=Record',dict(invoiceId=id,amount=amount,method=method,reference=reference,key=key or str(uuid.uuid4())))
 def test_invoice_payment_lifecycle_and_authorization(self):
  for page in ['/Manage/Index','/Manage/Payments','/Manage/Services','/Dispatch','/Admin']:
   code,html,url=web.ConfigurationTests.fetch(self.admin,page);self.assertEqual(code,200);self.assertIn(b'admin-sidebar',html)
  for client in [self.public,self.customer]:
   _,_,url=web.ConfigurationTests.fetch(client,'/Manage/Payments');self.assertTrue('/Denied' in url or '/Account/Login' in url)
  r=self.create_request();self.assertIsNone(self.invoice(r))
  self.assertEqual(web.ConfigurationTests.fetch(self.admin,'/Manage/Payments?handler=Create',b'requestId=1&total=100','application/x-www-form-urlencoded')[0],400)
  self.form('/Manage/Payments?handler=Create',dict(requestId=r,total=100,notes='Agreed repair'))
  invoice=self.invoice(r);self.assertEqual(invoice['total'],100);self.assertEqual(invoice['currency'],'USD');id=invoice['id']
  self.form('/Manage/Payments?handler=Create',dict(requestId=r,total=999));self.assertEqual(self.invoice(r)['total'],100)
  self.assertEqual(api(f'/service-requests/{r}/invoice',token=self.other)[0],400)
  self.assertEqual(api(f'/service-requests/{r}/invoice')[0],401)
  for amount in [-1,0,100.001,101]:self.payment(id,amount)
  self.payment(id,25,'Card','');self.assertEqual(self.invoice(r)['paid'],0)
  key=str(uuid.uuid4());self.payment(id,25,'EVCPlus','EVC-TEST-001',key);self.payment(id,25,'EVCPlus','EVC-TEST-001',key)
  self.assertEqual(self.invoice(r)['paid'],25);self.assertEqual(len(self.invoice(r)['payments']),1)
  # Competing payments must not both spend the same outstanding balance.
  keys=[str(uuid.uuid4()),str(uuid.uuid4())]
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
   list(pool.map(lambda k:self.payment(id,50,'Cash','',k),keys))
  current=self.invoice(r);self.assertEqual(current['paid'],75);self.assertEqual(current['balance'],25);self.assertEqual(current['status'],'Partially paid')
  self.payment(id,25,'Card','CARD-EXTERNAL-RECEIPT')
  current=self.invoice(r);self.assertEqual(current['balance'],0);self.assertEqual(current['status'],'Paid');self.assertEqual(len(current['payments']),3)
  self.form('/Manage/Payments?handler=Void',dict(invoiceId=id));self.assertEqual(self.invoice(r)['status'],'Paid')
  code,receipt,_=web.ConfigurationTests.fetch(self.customer,f'/Payments/Invoice/{r}');self.assertEqual(code,200);self.assertIn(b'PAY-',receipt)
  # An unpaid invoice can be voided, and receives no later payments.
  r2=self.create_request();self.form('/Manage/Payments?handler=Create',dict(requestId=r2,total=50));id2=self.invoice(r2)['id']
  self.form('/Manage/Payments?handler=Void',dict(invoiceId=id2));self.payment(id2,10)
  self.assertEqual(self.invoice(r2)['status'],'Void');self.assertEqual(self.invoice(r2)['paid'],0)
  # Issued invoices retain their currency after the business default changes.
  settings=web.ConfigurationTests.settings(self,**{'Input.Currency':'EUR'})
  self.form('/Manage/Settings',settings)
  eur_request=self.create_request();self.form('/Manage/Payments?handler=Create',dict(requestId=eur_request,total=10))
  self.assertEqual(self.invoice(eur_request)['currency'],'EUR');self.assertEqual(self.invoice(r)['currency'],'USD')
  self.form('/Manage/Settings',web.ConfigurationTests.settings(self))
  # All supported external payment methods record receipts without initiating charges.
  for method in ['Cash','EVCPlus','ZAAD','Sahal','BankTransfer','Card']:
   request=self.create_request();self.form('/Manage/Payments?handler=Create',dict(requestId=request,total=1));self.payment(self.invoice(request)['id'],1,method,'' if method=='Cash' else 'TEST-'+method);self.assertEqual(self.invoice(request)['status'],'Paid')

if __name__=='__main__':unittest.main(verbosity=2)

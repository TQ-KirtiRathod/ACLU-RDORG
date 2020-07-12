/**
 * Test Class for PhoneAsyncProcessor
 **/
@isTest
private class PhoneAsyncProcessorTest {
    public static List<phone__c> phonList = new List<Phone__c>();
	public static void setup(){
        Account acc = TestUtils.createAccount('Test Account', true);
        Contact con  = TestUtils.createContact(acc, 'Test firstName', 'Test lastName', true);
        Queueable_Control__c qc = TestUtils.createQueueableControl('MainQueueable', 0, 100, false);
        qc.Batch_Size_Phone__c=100;
        insert qc;
        for(Integer i = 0;i<10;i++){
            Phone__c p = TestUtils.createPhone(con.Id, '123456789'+i, false);
            p.IsPrimary__c =TRUE;
            phonList.add(p);
        }
        insert phonList;
    }
    
    @isTest
    static void testMethod1(){
        setup();
        List<Id> phoneIdList = new List<Id>();
        String phoneid;
        for(Phone__c p: phonList){
            phoneid = p.Id+',';
        }
        AsyncRequest__c ar = new AsyncRequest__c();
        ar.Params__c = phoneid;
        Test.startTest();
        PhoneAsyncProcessor pap = new PhoneAsyncProcessor(ar);
        pap.phone_primarySet();
        Test.stopTest();
        system.assert(pap.PhoneObjs.size() > 0);
    }
}
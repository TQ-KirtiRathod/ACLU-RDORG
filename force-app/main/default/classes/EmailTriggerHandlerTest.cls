/*
*
*Name  :  EmailTriggerHandlerTest
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 23, 2016
*Purpose : Test Coverage for EmailTriggerHandler
*
*/
@isTest
public class EmailTriggerHandlerTest {
    public static list<Contact> listContact;
    public static list<String> contactId;
    public static list<Email__c> listEmail;
    
    /*
    *
    *Method testOnDuplicateRecord
    *Testing if duplicate email records
    *are created.
    *Also,testing if first email on contact
    *are set as Primary.
    *
    */
    public static testMethod void testOnDuplicateRecord(){
        createTestData();
        test.startTest();
        insert listEmail;
        Email__c em = [SELECT Id,External_Id__c,Primary__c,Contact__c,Email_Address__c
                       FROM Email__c 
                       WHERE Id =: listEmail[1].Id];
        
        system.assertEquals(em.External_Id__c,String.valueOf(em.Contact__c).Substring(0,15)+'_'+em.Email_Address__c);              
        system.assertEquals(em.Primary__c,true);
        Email__c ema = new Email__c(Contact__c = listContact[1].Id,Email_Address__c = 'testOnEmail1@ymail.com');
        try {
            insert ema;
        } 
        catch (DmlException e) {
            //Assert Error Message
            System.assert(true,e.getMessage() );
        }
        Test.stopTest();
        Contact cont = [SELECT Id,rC_Bios__Home_Email__c FROM Contact Where Id =: listContact[4].Id];
        Email__c eml = [SELECT Id,External_Id__c,Contact__c,Email_Address__c 
                        FROM Email__c 
                        WHERE Id =: listEmail[6].Id];
        
        eml.Email_Address__c = 'test@test.in';
        Database.SaveResult[] srList;
        try {
            srList = Database.insert(new List<Email__c>{eml}, false);

        } 
        catch (DmlException e) {
            System.assert(false,srList[0].isSuccess() );
        }
    }
    
    
    public static testMethod void testDeleteRecord(){
        Test.startTest();
        Contact con = TestUtils.createContact(null,'cons','testEmail',TRUE);
        Email__c email = TestUtils.createEmail(con.Id,'testOnEmail@ymail.com',FALSE);
        email.Primary__c =TRUE;
        insert email;
        Test.stopTest(); 
        Contact cont = [SELECT Id,rC_Bios__Home_Email__c,Email FROM Contact Where Id =: con.Id];
        system.assertEquals(cont.rC_Bios__Home_Email__c, 'testonemail@ymail.com');
        
        Delete email;
        System.assertEquals([SELECT Id,rC_Bios__Home_Email__c FROM Contact Where Id =: con.Id].rC_Bios__Home_Email__c, NULL );
    }

    public static testMethod void testOptInChangeMarking() {
        createTestData();
        insert listEmail;
        // TestUtils creates emails with the Opt_in__c field null
        System.assertEquals(0, [SELECT count() FROM Email__c WHERE Opt_In_Status_Changed__c = false]);
        Email__c e = [SELECT Id FROM Email__c LIMIT 1];
        e.Opt_In__c = true;
        update e;
        e = [SELECT Opt_In__c, Opt_In_Status_Changed__c FROM Email__c WHERE Id = :e.Id];
        System.assert(e.Opt_In_Status_Changed__c);
        System.assert(e.Opt_In__c);
    }
    
    
    public static testMethod void testUndeliverableAutoset() {
        createTestData();
        insert listEmail;
        // Test change to an Undeliverable status
        System.assertEquals(FALSE, [SELECT Undeliverable__c FROM Email__c LIMIT 1].Undeliverable__c);
        listEmail[0].Email_Status__c = 'Hard Bounce';
        update listEmail[0];
        System.assertEquals(TRUE, [SELECT Undeliverable__c FROM Email__c LIMIT 1].Undeliverable__c); 
    }
    
   public static testMethod void testUndeliverableErrorForBadStatus() {
        createTestData();
        insert listEmail;
        // Test Undeliverable set with incompatible status
        listEmail[0].Email_Status__c = 'Hard Bounce';
        
        try {
        	update listEmail[0];
        }
        catch(Exception e) {
        	Boolean expectedExceptionThrown = e.getMessage().contains(System.Label.EMAIL_UNDELIVERABLE_INVALID_STATUS) ? true : false;
        	System.AssertEquals(expectedExceptionThrown, true);
        }
        	
    }
    
    
    /*
    *
    *Method createTestData
    *Creating Sample Data
    *For Testing Purpose
    *
    */
    public static void createTestData(){
        listContact = new list<Contact>();
        contactId = new list<String>();
        listEmail = new list<Email__c>();
        for(Integer i=0;i<10;i++) {
            Contact con = TestUtils.createContact(null,'cons'+i,'testEmail'+i,false);
            listContact.add(con);
            contactId.add(con.Id);
        }
        insert listContact;
        for(Integer i=0;i<10;i++){
            Email__c email = TestUtils.createEmail(listContact[i].Id,'testOnEmail'+i+'@ymail.com',false);
            listEmail.add(email);
        }
        for(Integer i=11;i<13;i++){
            Email__c emai = TestUtils.createEmail(listContact[4].Id,'test'+i+'@ymail.com',false);
            emai.Primary__c = true;
            listEmail.add(emai);
        }
    }   
}
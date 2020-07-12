//Created a test class by RoundCorner ZenDesk #57433
@isTest
public class UpdateLegacyOnEmail_BatchTest {
    
    public static list<Contact> listContact;
    public static list<String> contactId;
    public static list<Email__c> listEmail;
    public static testMethod void testOnDuplicateRecord(){
        createTestData();
        
        insert listEmail;
        DateTime startDateTime = System.now().addMonths(-65);
        DateTime endDateTime = System.now().addMonths(64);
        test.startTest();
        Database.executeBatch(new UpdateLegacyOnEmail_Batch(startDateTime, endDateTime ), 200);
        Test.stopTest();
        Email__c em = [SELECT Id,External_Id__c,Primary__c,Contact__c,Email_Address__c
                       FROM Email__c 
                       WHERE Id =: listEmail[1].Id];
                      
        system.assertEquals(em.Primary__c,true);
        
        
        
    }
    public static testMethod void testOnEmailRecord(){
        createTestData();
        
        insert listEmail;
        String emails = '';
        for(Email__c emailObj :listEmail) {
            emails += emails+emailObj.id;
        }
        DateTime startDateTime = System.now().addMonths(-65);
        DateTime endDateTime = System.now().addMonths(64);
        test.startTest();
        Database.executeBatch(new UpdateLegacyOnEmail_Batch(emails), 200);
        Test.stopTest();
        Email__c em = [SELECT Id,External_Id__c,Primary__c,Contact__c,Email_Address__c
                       FROM Email__c 
                       WHERE Id =: listEmail[1].Id];
       
        system.assertEquals(em.Primary__c,true);
        
        
        
    }
    public static testMethod void testOnEmailStartDateRecord(){
        createTestData();
       
        insert listEmail;
        String emails = '';
        for(Email__c emailObj :listEmail) {
            emails += emails+emailObj.id;
        }
        DateTime startDateTime = System.now().addMonths(-65);
        test.startTest();
        Database.executeBatch(new UpdateLegacyOnEmail_Batch(startDateTime), 200);
		 Test.stopTest();        
        Email__c em = [SELECT Id,External_Id__c,Primary__c,Contact__c,Email_Address__c
                       FROM Email__c 
                       WHERE Id =: listEmail[1].Id];
        system.assertEquals(em.Primary__c,true);
        
       
        
    }
    public static void createTestData(){
        listContact = new list<Contact>();
        //contactId = new list<String>();
        listEmail = new list<Email__c>();
        for(Integer i=0;i<7;i++) {
            Contact con = TestUtils.createContact(null,'cons'+i,'testEmail'+i,false);
            listContact.add(con);
        }
        insert listContact;
        for(Integer i=0;i<5;i++){
            Email__c email = TestUtils.createEmail(listContact[i].Id,'testOnEmail'+i+'@ymail.com',false);
            email.External_Id__c =  '1234'+String.valueOf(i);
            listEmail.add(email);
        }
        
    }   

}
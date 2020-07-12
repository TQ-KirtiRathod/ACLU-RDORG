/**
 *
 *
 * @author  Surya pratap, Traction on Demand
 * @Date    2019-06-18
 */

@IsTest
private class trac_DeceasedContactCtlrTest {
    private static Account acct;
    private static Contact contact;
    private static Contact secondaryContact;
    private static Phone__c phone;
    private static Email__c email;
    
    private static Id houseHoldId;
    static {        
        
        houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        
        //Insert Account
        acct = TestUtils.createAccount('Account',false);
        acct.RecordTypeId = houseHoldId;
        acct.rC_Giving__Active_Sustainer__c = true;
        insert acct;
        
        // Inserting contac
        contact = TestUtils.createContact(acct,'firstName','lastName',false);
        contact.rC_Bios__Preferred_Contact__c = true;
        contact.rC_Bios__Active__c = true;
        contact.rC_Bios__Deceased__c = false;
        contact.rC_Bios__Secondary_Contact__c = false;
        insert contact;

        // Inserting contac
        secondaryContact = TestUtils.createContact(acct,'firstName','lastName',false);
        secondaryContact.rC_Bios__Preferred_Contact__c = false;
        secondaryContact.rC_Bios__Active__c = true;
        secondaryContact.rC_Bios__Deceased__c = false;
        secondaryContact.rC_Bios__Secondary_Contact__c = true;
        insert secondaryContact;
        
        phone = TestUtils.createPhone(contact.Id, '123453455', false);
        phone.Phone_Status__c = 'Valid';
        phone.IsPrimary__c = true;
        phone.Universal_SMS_Opt_Out__c = false;
        insert phone;
        
        email = TestUtils.createEmail(contact.Id, 'test@aclu.com', false);
        email.Email_Status__c = 'Valid';
        email.Opt_In__c = true;
        email.Primary__c = true;
        insert email;

        acct.rC_Bios__Preferred_Contact__c = contact.Id;
        acct.Is_Email_Salutation_Locked__c = true;
        acct.rC_Bios__Secondary_Contact__c = secondaryContact.Id;
        update acct;
        
    }
    
    @IsTest
    static void trac_getContact_recordId() {
        Contact newContact;
        	Test.startTest();
        		newContact = trac_DeceasedContactCtlr.getContact(contact.Id);
        	Test.stopTest();
        System.assertEquals(newContact.Id, contact.Id);
    }
    
    @IsTest
    static void trac_getContact_nullRecordId() {
        Contact newContact;
        Test.startTest();
        	newContact = trac_DeceasedContactCtlr.getContact(null);
        Test.stopTest();
        System.assertEquals(null, newContact);
    }
    
    @IsTest
    static void trac_updateContact() {
        Map<String, String> response = new Map<String, String>();
        String resp;
        Contact newContact;
        
        Test.startTest();
        	contact.rC_Bios__Deceased__c = true;
        	contact.rC_Bios__Deceased_Year__c = '2000';
            resp = trac_DeceasedContactCtlr.updateContact(JSON.serialize(contact));
        	response = (Map<String, String>)JSON.deserialize(resp, Map<String, String>.class);
        	newContact = [SELECT Id, rC_Bios__Deceased_Year__c FROM Contact WHERE Id =: contact.Id];
        Test.stopTest();
        
        System.assertEquals('2000', contact.rC_Bios__Deceased_Year__c);
        System.assertEquals(true, contact.rC_Bios__Deceased__c);
    }
    
    @IsTest
    static void trac_updateContact_exception() {
        Map<String, String> response = new Map<String, String>();
        String resp;
        Contact newContact;
        
        Test.startTest();
        	contact.rC_Bios__Deceased__c = true;
        	contact.rC_Bios__Deceased_Year__c = '';
            resp = trac_DeceasedContactCtlr.updateContact(JSON.serialize(contact));
        	response = (Map<String, String>)JSON.deserialize(resp, Map<String, String>.class);
        	newContact = [SELECT Id, rC_Bios__Deceased__c FROM Contact WHERE Id =: contact.Id];
        Test.stopTest();
        
        System.assertEquals(newContact.rC_Bios__Deceased__c, false);
        System.assertEquals('error',response.get('status'));
    }
    
    @IsTest
    static void trac_getDeceasedDateAndHelpTextInfo() {
        Object response;
        Map<String, Object> responseDeceasedDate = new Map<String, List<String>>();
        String resp;
        
        Test.startTest();
        	resp = trac_DeceasedContactCtlr.getDeceasedDateAndHelpTextInfo();
        	response = JSON.deserializeUntyped(resp);
        	responseDeceasedDate = (Map<String, Object>)( (Map<String, Object>)response).get('DeceasedDate');
        Test.stopTest();
        
        System.assertEquals(32, ((List<Object>)responseDeceasedDate.get('DeceasedDay')).size());
        System.assertEquals(13, ((List<Object>)responseDeceasedDate.get('DeceasedMonth')).size());
        System.assertNotEquals(0, ((List<Object>)responseDeceasedDate.get('DeceasedYear')).size());
        
    }
}
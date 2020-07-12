@IsTest
public class trac_HandleDeceasedContactTest {
	private static Account acct;
    private static Contact contact;
    private static Contact secondaryContact;
    private static Phone__c phone;
    private static Email__c email;
    
    private static Id account_RT_houseHoldId;
    private static Id contact_RT_houseHoldId;
    
    private static void createTestData() {
        account_RT_houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contact_RT_houseHoldId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        
        //Insert Account
        acct = TestUtils.createAccount('Account',false);
        acct.RecordTypeId = account_RT_houseHoldId;
        acct.rC_Giving__Active_Sustainer__c = true;
        acct.All_Contacts_Deceased__c = false;
        insert acct;
        
        // Inserting contac
        contact = TestUtils.createContact(acct,'firstName','lastName',false);
        contact.RecordTypeId = contact_RT_houseHoldId;
        contact.rC_Bios__Preferred_Contact__c = true;
        contact.rC_Bios__Active__c = true;
        contact.rC_Bios__Deceased__c = false;
        contact.rC_Bios__Secondary_Contact__c = false;
        insert contact;


        
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


        
    }
    
    @IsTest
    static void trac_startDeceaseContactProcess() {createTestData();
        // Inserting contac
        secondaryContact = TestUtils.createContact(acct,'firstName2','lastName2',false);
        secondaryContact.RecordTypeId = contact_RT_houseHoldId;
        secondaryContact.rC_Bios__Preferred_Contact__c = false;
        secondaryContact.rC_Bios__Active__c = true;
        secondaryContact.rC_Bios__Deceased__c = false;
        secondaryContact.rC_Bios__Secondary_Contact__c = true;
        insert secondaryContact;
        acct.rC_Bios__Preferred_Contact__c = contact.Id;
        acct.Is_Email_Salutation_Locked__c = true;
        acct.rC_Bios__Secondary_Contact__c = secondaryContact.Id;
        acct.rC_Giving__Active_Sustainer__c = true;
        update acct;
        Test.startTest();

            for(Account objAcc : [SELECT Id, All_Contacts_Deceased__c FROM Account WHERE Id = :acct.Id]) {
                System.assertEquals(objAcc.All_Contacts_Deceased__c, false);
            }
            contact.rC_Bios__Deceased_Day__c = '03';
            contact.rC_Bios__Deceased_Month__c = '05';
            contact.rC_Bios__Deceased_Year__c = '2007';
            contact.rC_Bios__Deceased__c = true;
            update contact;
        	//trac_HandleDeceasedContacts.startDeceaseContactProcess(new List<Contact>{contact}, new Map<Id,Id>{acct.id => contact.Id});
            for(Account objAcc : [SELECT Id, All_Contacts_Deceased__c FROM Account WHERE Id = :acct.Id]) {
                System.assertEquals(objAcc.All_Contacts_Deceased__c, false);
            }
        Test.stopTest();

    }

    @IsTest
    static void trac_startDeceaseContactProcessWithAllDeceased() {
        Test.startTest();
        createTestData();
/*        for(Account objAcc : [SELECT Id, All_Contacts_Deceased__c FROM Account WHERE Id =:acct.Id]) {
            System.assertEquals(objAcc.All_Contacts_Deceased__c, false);
        }*/
        List<rC_Bios__Preference__c> preferences = [SELECT Id, rC_Bios__Account__c FROM rC_Bios__Preference__c WHERE rC_Bios__Account__c = :acct.Id];
        System.assertEquals(true, preferences.isEmpty(), 'No preference record exists.');
/*        delete secondaryContact;*/
        contact.rC_Bios__Deceased_Day__c = '03';
        contact.rC_Bios__Deceased_Month__c = '05';
        contact.rC_Bios__Deceased_Year__c = '2007';
        contact.rC_Bios__Deceased__c = true;
        update contact;
        Test.stopTest();
        //trac_HandleDeceasedContacts.startDeceaseContactProcess(new List<Contact>{contact}, new Map<Id,Id>{acct.id => contact.Id});
        for(Account objAcc : [SELECT Id, All_Contacts_Deceased__c FROM Account WHERE Id =:acct.Id]) {
            System.assertEquals(objAcc.All_Contacts_Deceased__c, true);
        }
        preferences = [SELECT Id, rC_Bios__Account__c FROM rC_Bios__Preference__c WHERE rC_Bios__Account__c = :acct.Id];
        System.assertEquals(false, preferences.isEmpty(), 'No preference record exists.');

    }


}
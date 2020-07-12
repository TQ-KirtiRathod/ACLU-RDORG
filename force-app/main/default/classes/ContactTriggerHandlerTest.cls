/*
*
*Name  :  ContactTriggerHandlerTest
*Author:  Appirio India
*Date  :  May 19, 2017
*Purpose : Test Class for ContactTriggerHandler
*
*/
@isTest
private class ContactTriggerHandlerTest {
    private static Id houseHoldId;
    private static List<Contact> contacts;
    private static List<Account> accounts;
    
    static {
        houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    }
    
    /*
    *
    * Method testContactDeceasedFunc
    * Testing Contact Deceased Functionality.
    */
	private static testMethod void testAllContactDeceased() {
	  createTestData();
	  
        Test.startTest();
            insert contacts;
            
            for(Account objAcc : [SELECT Id, All_Contacts_Deceased__c FROM Account WHERE Id IN: accounts]) {
                system.assertEquals(objAcc.All_Contacts_Deceased__c, false);
            }
            
            for(Contact objContact : contacts) {
                objContact.rC_Bios__Deceased_Day__c = '03';
                objContact.rC_Bios__Deceased_Month__c = '05';
                objContact.rC_Bios__Deceased_Year__c = '2007';
                objContact.rC_Bios__Deceased__c = true;
            }
            
            if(!contacts.isEmpty()) {
                update contacts;
            }
            
            for(Account objAcc : [SELECT Id, All_Contacts_Deceased__c FROM Account WHERE Id IN: accounts]) {
                system.assertEquals(objAcc.All_Contacts_Deceased__c, true);
            }
	  Test.stopTest();
	}

    /*
    *
    * Method testpopulateSortNameOnHouseholdAccounts
    * Testing populateSortNameOnHouseholdAccounts Functionality.
    */
    private static testMethod void testpopulateSortNameOnHouseholdAccounts() {
      createTestData();
      
        Test.startTest();
            insert contacts;
            
            for(Account objAcc : [SELECT Id, Sort_Name__c, All_Contacts_Deceased__c FROM Account WHERE Id IN: accounts]) {
                system.assertEquals(objAcc.Sort_Name__c, 'lastName, firstName');
            }
            
            for(Contact objContact : contacts) {
                objContact.lastName = 'UpdatedLastName';
            }
            
            if(!contacts.isEmpty()) {
                update contacts;
            }
            
            for(Account objAcc : [SELECT Id, Sort_Name__c, All_Contacts_Deceased__c FROM Account WHERE Id IN: accounts]) {
                system.assertEquals(objAcc.Sort_Name__c, 'UpdatedLastName, firstName');
            }
      Test.stopTest();
    }

    /*
    *
    * Method testSecondaryCntAsPrimary
    * Testing: Make the secondaryContact as Primary if the Primary Contact deceased.
    */
	private static testMethod void testSecondaryCntAsPrimary() {
	    List<Contact> contactsToUpdate = new List<Contact>();
        createTestData();
        
        Contact cont = TestUtils.createContact(accounts[0],'firstName','lastName',false);
        cont.rC_Bios__Secondary_Contact__c = true; 
        cont.rC_Bios__Active__c = true;
        contacts.add(cont);
        
        insert contacts;
         
        Test.startTest();
            
            contacts[0].rC_Bios__Deceased__c = true;
            update contacts[0];
            
            
            for(Contact objContact : [SELECT Id, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c From Contact WHERE Id =: contacts[0].Id]) {
                system.assertEquals(objContact.rC_Bios__Preferred_Contact__c, true);
                system.assertEquals(objContact.rC_Bios__Secondary_Contact__c, false);
            }
            
        Test.stopTest();
	}
	
    /*
    *
    * Method testRDValuePropagation
    * Testing RDValuePropagation functionality from ContactTriggerHandler Class
    */
    private static TestMethod void testRDValuePropagation() {
        
        createTestData();
	  
        Test.startTest();
            insert contacts;
            
            for(Contact objContact : [SELECT Id, GOL_Current_Amount__c, HPC36_Amount__c, Account.GOL_Current_Amount__c, Account.HPC36_Amount__c FROM Contact WHERE Id IN: contacts]) {
                system.assertEquals(objContact.GOL_Current_Amount__c, objContact.Account.GOL_Current_Amount__c);
                system.assertEquals(objContact.HPC36_Amount__c, objContact.Account.HPC36_Amount__c);
            }
	  Test.stopTest();
    }
    
    /*
    *
    * Method testDeleteTrigger
    * Testing Contact Delete functionality related to ContactTriggerHandler
    */
    @isTest
    private static void testDeleteTrigger() {
		List<Contact> ctlist = new List<Contact>();
		Test.startTest();
		for(Integer i = 0; i < 2; i++){
			ctlist.add(TestUtils.createContact(null, 'fn', 'ln', false));
  		}

      	insert ctlist;

      	List<Contact> cts = [SELECT Id, Contact_Number__c, RecordType.Name FROM Contact LIMIT 2];
      	Contact a = new Contact(Id = cts[1].Id), b = new Contact(Id = cts[0].Id);
      	merge b a;

      	List<Contact_Merge_History__c> hists;

      	hists = [SELECT Deleted_Contact_Number__c, Deleted_Id__c, Merged_Date__c, Record_Type__c,
                      Retained_Contact__c, Retained_Contact_Number__c, Retained_Id__c
               FROM Contact_Merge_History__c];
		Test.stopTest();
  		System.assertEquals(1, hists.size());
  		System.assertEquals(cts[0].Id, hists[0].Retained_Id__c);
	  	System.assertEquals(cts[0].Id, hists[0].Retained_Contact__c);
	  	System.assertEquals(cts[0].Contact_Number__c, hists[0].Retained_Contact_Number__c);
	  	System.assertEquals(cts[1].Id, hists[0].Deleted_Id__c);
	  	System.assertEquals(cts[1].Contact_Number__c, hists[0].Deleted_Contact_Number__c);
	  	System.assertEquals(Date.today(), hists[0].Merged_Date__c);
	  	System.assertEquals(cts[1].RecordType.Name, hists[0].Record_Type__c);      
    }

	/*
    *
    * Method UpdateContactLookup
    * Testing if AccountLookup updated then RelatedNGOC object shares is re-calculated.
    */
	private static testMethod void UpdateContactLookup() {
		List<Account> accounts = new List<Account>(); 
		Map<String,Id> mapGroupNameToId = new map<String,Id>();
		
		Test.startTest();
		
		// Account Records
        for(Integer i=0;i<2;i++){   
            Account acct = TestUtils.createAccount('Account'+i,false);
            acct.RecordTypeId = houseHoldId;
            acct.Affiliation__c = 'NN';
            acct.BillingPostalCode = '00000';
            acct.BillingCountry = 'Japan';
            accounts.add(acct);
        }   
        if(!accounts.IsEmpty()){
			insert accounts;
        }
        
        Account acc1 = accounts[0];
        Account acc2 = accounts[1];
        Account account2 = [select id,Affiliation__c FROM Account WHERE Id=:acc2.Id];
		Contact con2 = TestUtils.createContact(account2,'firstName2','lastName2',true);
		Contact con1 = TestUtils.createContact(account2,'firstName2','lastName2',true);
		rC_Bios__Preference__c Pre = TestUtils.CreatePreferencesUsingContact(con2.Id,true);
		rC_Bios__Salutation__c Sl = TestUtils.CreateSalutationUsingContact(con2.Id,true);
		rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlanUsingContact(con2.Id,true);
		rC_Bios__Relationship__c RS = TestUtils.CreateRelationShipUsingContact(con2.Id, con2.Id, true);
		Prospect_Research__c prospect = TestUtils.CreateProspectResearch(con2.Id, true);
            
		for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        account ac = [SELECT Affiliation__c FROM account WHERE Id =: acc1.Id];
		ac.Affiliation__c = 'ZF';
		update ac;
		
		//update contact's account lookup
		List<contact> co = new List <contact>();
		for(contact con:  [SELECT Id,accountId FROM contact WHERE Id =: con2.Id OR Id =: con1.Id]){
			con.accountId = accounts[0].Id;
			co.add(con);
		}
		update co;
		
		
		
		//Preference
		 for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('ZF')]){
            system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('ZF'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Preference__share> preShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND AccessLevel = 'Edit'];
        system.assertEquals(preShare.size(),1); 
        
        //Salutation 
        for(rC_Bios__Salutation__share salShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('ZF')]){
            system.assertEquals(salShare.UserOrGroupId,mapGroupNameToId.get('ZF'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Salutation__share> salShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND AccessLevel = 'Edit'];
        system.assertEquals(salShare.size(),1); 
        
        //Relationship
         for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('ZF')]){
            system.assertEquals(RSShare.UserOrGroupId,mapGroupNameToId.get('ZF'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Relationship__share> reShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND AccessLevel = 'Edit'];
        system.assertEquals(reShare.size(),1); 
		Test.StopTest();
	}
	
	/*
    *
    * Method createTestData
    * Creating Test Data
    */
	private static void createTestData() {
	    accounts = new List<Account>();
	    contacts = new List<Contact>();
	    Account acct;
	    Contact cont;
	    
	    // Account Records
        for(Integer i=0 ;i<10; i++){   
            acct = TestUtils.createAccount('Account'+i,false);
            acct.RecordTypeId = houseHoldId;
            acct.HPC36_Amount__c = 1;
            acct.GOL_Current_Amount__c = 2;
            accounts.add(acct);
        }   
        
        if(!accounts.IsEmpty()){
			insert accounts;
        }
        
        // Contact Records
        for(Integer i=0 ;i<10; i++){   
            cont = TestUtils.createContact(accounts[i],'firstName','lastName',false);
            cont.rC_Bios__Preferred_Contact__c = true;
            cont.rC_Bios__Active__c = true;
            cont.rC_Bios__Deceased__c = false;
            cont.rC_Bios__Secondary_Contact__c = false;
            contacts.add(cont);
        }   
	}
}
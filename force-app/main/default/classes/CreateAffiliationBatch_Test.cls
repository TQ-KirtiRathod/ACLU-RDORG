/*
*
*Name  :  CreateAffiliationBatch_Test
*Author:  Appirio India (Kajal Jalan)
*Date  :  December 09, 2016
*Purpose : Test Coverage for CreateAffiliationBatch
*
*/

@isTest
private class CreateAffiliationBatch_Test {
   
    public static List<Account> listAccounts;
    public static List<Account> accountList;  
    public static rC_Bios__Action_Plan__c Acp;
    public static rC_Bios__Salutation__c sal;
    public static rC_Bios__Preference__c Pre;
    public static rC_Giving__Payment_Method__c PM; 
    public static rC_Bios__Relationship__c RS;
    public static rC_Giving__Planned_Giving__c pg;
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    
    /*
    *
    *Method testForAffiliation
    *Testing the Account ShareRecords
    *
    */
    
    private static testMethod void testForAffiliation() {
    	List<TriggerSettings__c> updateTriggerSettings = new List<TriggerSettings__c>(); 
    	Map<String,Id> mapGroupNameToId = new map<String,Id>();
    	Map<Id,String> mapAccountIdToAffilate = new map<Id,String>();
    	
        createTestData();       
      //  for(Account acc: [SELECT id,Affiliation__c FROM Account ]){
       //     mapAccountIdToAffilate.put(acc.Id,acc.Affiliation__c);
       // }
        
       // Map<String, TriggerSettings__c> triggerSetting = TriggerSettings__c.getAll();
       // for(Group gp: [SELECT id, name FROM group WHERE name=:mapAccountIdToAffilate.values()]){
        //    mapGroupNameToId.put(gp.name,gp.Id);
       // }
        
        Test.startTest();
        system.assertEquals(0,[SELECT Id, AccountAccessLevel, UserOrGroupId, AccountId FROM AccountShare where AccountId =:listAccounts AND AccountAccessLevel = 'Edit'].Size());
        
        for(TriggerSettings__c obj: [SELECT isTestMode__c FROM TriggerSettings__c]){
       	obj.isTestMode__c = true;
        updateTriggerSettings.add(obj);
       }
        
        if(!updateTriggerSettings.IsEmpty())
       	update updateTriggerSettings;
        Database.executebatch(new CreateAffiliationBatch(), 200);
        
        Test.stopTest();
        
        //for(AccountShare accShare: [SELECT Id, AccountAccessLevel, UserOrGroupId, AccountId FROM AccountShare where AccountId =:listAccounts AND AccountAccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
          //  system.assertEquals(accShare.UserOrGroupId,mapGroupNameToId.get('NN'));
       // }
        
        //Preference Share
       // for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where ParentId =:Pre.id AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
       //     system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('NN'));
      //  }
        
        // PaymentMethod Share
       // for(rC_Giving__Payment_Method__share pmShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Payment_Method__share where ParentId =:PM.Id AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
        //    system.assertEquals(pmShare.UserOrGroupId,mapGroupNameToId.get('NN'));
       // }
        
        //Salutation share
        //for(rC_Bios__Salutation__share slShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where ParentId =:sal.Id AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
         //   system.assertEquals(slShare.UserOrGroupId,mapGroupNameToId.get('NN'));
      //  }
        
        // PlannedGiving Share
       // for(rC_Giving__Planned_Giving__share GpShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Planned_Giving__share where ParentId =:pg.Id AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
       //     system.assertEquals(GpShare.UserOrGroupId,mapGroupNameToId.get('NN'));
       // }
        
        // ActionPlan Share
      //  for(rC_Bios__Action_Plan__share ApShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Action_Plan__share where ParentId =:Acp.Id AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
       //     system.assertEquals(ApShare.UserOrGroupId,mapGroupNameToId.get('NN'));
       // }
        
        // Relationship Share
        //for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where ParentId =:Rs.Id AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
        //    system.assertEquals(RSShare.UserOrGroupId,mapGroupNameToId.get('NN'));
       // }
        
    }
    
    /*
    *
    *Method createTestData
    *Sample Data for testing
    *
    */
    private static testMethod void checkException(){
        List<TriggerSettings__c> updateTriggerSettings = new List<TriggerSettings__c>(); 
     	 createData(); 
         
         accountList.get(0).rC_Bios__Preferred_Contact__c=null;
        //accountList.get(0).rC_Giving__Maximum_Matched__c=1000;
        
         Test.startTest();
        system.assertEquals(0,[SELECT Id, AccountAccessLevel, UserOrGroupId, AccountId FROM AccountShare where AccountId =:accountList AND AccountAccessLevel = 'Edit'].Size());
        
        for(TriggerSettings__c obj: [SELECT isTestMode__c FROM TriggerSettings__c]){
        	obj.isTestMode__c = true;
       	    updateTriggerSettings.add(obj);
       }
        
        if(!updateTriggerSettings.IsEmpty())
        	update updateTriggerSettings;
        
        CreateAffiliationBatch obj = new CreateAffiliationBatch();        
        obj.execute(null,accountList);
       
        Test.stopTest();
        
    }
    
    private static void createTestData(){
        
        listAccounts = new List<Account>();
        
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.RecordTypeId = houseHoldId;  
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.Is_Shared_Group__c=true;
            listAccounts.add(acc);
        }   
        
        Account a1 = TestUtils.createAccount('Account',false);
        a1.RecordTypeId = houseHoldId;
        a1.BillingPostalCode = '00000';
        a1.BillingCountry = 'Japan';
        a1.Is_Shared_Group__c=true;
        
        TestUtils.createTriggerSettings('Account_Trigger',true);
        TestUtils.createTriggerSettings('ActionPlan_Trigger',true);
        TestUtils.createTriggerSettings('Salutation_Trigger',true);
        TestUtils.createTriggerSettings('Preference_Trigger',true);
        TestUtils.createTriggerSettings('PaymentMethod_Trigger',true);
        TestUtils.createTriggerSettings('PlannedGiving_Trigger',true);
        TestUtils.createTriggerSettings('Relationship_Trigger',true);
         
        insert listAccounts;
        insert a1;
        
        for(account oacc: listAccounts){
	    	Acp= TestUtils.CreateActionPlan(oacc.Id,true);
	        sal = TestUtils.CreateSalutation(oacc.Id,true);
	        Pre = TestUtils.CreatePreferences(oacc.Id,true);
	        PM = TestUtils.CreatePaymentMethod(oacc.Id,true);
	        RS = TestUtils.CreateRelationShip(oacc.Id, a1.Id, true);
	        pg = TestUtils.CreatePlannedGiving(oacc.Id, a1.Id, true);
		}
    }
    private  static void createData(){
       accountList = new List<Account>();
        for(Integer i= 0; i<10;i++){
        Account a1 = TestUtils.createAccount('Account',false);
        a1.RecordTypeId = houseHoldId;
       	a1.Affiliation__c = 'NN';
        a1.BillingPostalCode = '00000';
       // a1.rC_Giving__Minimum_Matched__c=10000;
        //a1.rC_Giving__Maximum_Matched__c=1000;    
        a1.BillingCountry = 'Japan';
        a1.Is_Shared_Group__c=true;		
        accountList.add(a1);
        }
               
        TestUtils.createTriggerSettings('Account_Trigger',true);
        TestUtils.createTriggerSettings('ActionPlan_Trigger',true);
        TestUtils.createTriggerSettings('Salutation_Trigger',true);
        TestUtils.createTriggerSettings('Preference_Trigger',true);
        TestUtils.createTriggerSettings('PaymentMethod_Trigger',true);
        TestUtils.createTriggerSettings('PlannedGiving_Trigger',true);
        TestUtils.createTriggerSettings('Relationship_Trigger',true);
        
         
        Account a2 = TestUtils.createAccount('Account',false);
        a2.RecordTypeId = houseHoldId;
        a2.BillingPostalCode = '00000';
        a2.BillingCountry = 'Japan';
        a2.Is_Shared_Group__c=true;
        
        //insert accountList;
        insert a2;
         //for(account oacc: accountList){
	    	//= TestUtils.CreateActionPlan(oacc.Id,true);
	       // sal = TestUtils.CreateSalutation(oacc.Id,true);
	       // Pre = TestUtils.CreatePreferences(oacc.Id,true);
	        //PM = TestUtils.CreatePaymentMethod(oacc.Id,true);
	       // RS = TestUtils.CreateRelationShip(oacc.Id, a2.Id, true);
	        //pg = TestUtils.CreatePlannedGiving(oacc.Id, a2.Id, true);
		//} 
    }
     
}
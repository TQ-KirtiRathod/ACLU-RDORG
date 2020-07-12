/*
*Name  :  ActionPlanTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 23, 2016
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
private class ActionPlanTriggerHandlerTest {
    /*
    *Method ActionPlanAccountLookupSharingTest 
    *Testing if ActionPlan record created then share is created based on related affiliate.
    */
    static testMethod void actionPlanAccountLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapActionPlanIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        //List<rC_Bios__Action_Plan__share> ActionPlanSharesToBeInsert = new List<rC_Bios__Action_Plan__share>(); 
        List<rC_Bios__Action_Plan__c> actionPlanUpdates = new List<rC_Bios__Action_Plan__c>(); 
        List<Account> Accounts = [SELECT Id, Affiliation__c, BillingCountry, BillingPostalCode FROM Account];
        
        Test.startTest();
        
        // Preference Records
        for(Integer i=0;i<2;i++){   
            rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlan(Accounts[i].Id,true);
            mapActionPlanIdToAffilate.put(Ap.Id,Accounts[i].Affiliation__c); 
        }
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        // changing the account lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        for(Id objId: mapActionPlanIdToAffilate.Keyset()){
            rC_Bios__Action_Plan__c pre = new rC_Bios__Action_Plan__c();
            pre.Id = objId;
            pre.rC_Bios__WhatId__c = acc.id;
            actionPlanUpdates.add(pre);
        }
        
        if(!actionPlanUpdates.isEmpty()){
            update actionPlanUpdates;
        }
        
        //Test Delete
        delete actionPlanUpdates;
        System.assertEquals(0, [SELECT Id FROM rC_Bios__Action_Plan__c].size());
        Test.stopTest();
        // check the Previous deleted records
        //List<rC_Bios__Action_Plan__share> apShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Action_Plan__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapActionPlanIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        //system.assertEquals(apShare.size(),0); 
    }
    
    /*
    *Method ActionPlanContactLookupSharingTest 
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void actionPlanContactLookupSharingTest() {
        List<rC_Bios__Action_Plan__c> actionPlans = new List<rC_Bios__Action_Plan__c>();
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapActionPlanIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        List<rC_Bios__Action_Plan__c> actionPlanUpdate = new List<rC_Bios__Action_Plan__c>();
        List<Account> Accounts = [SELECT Id, Affiliation__c, BillingCountry, BillingPostalCode FROM Account];
        List<Contact> Contacts = [SELECT Id, LastName, AccountId FROM Contact];
        
        Test.startTest();
        // Action Plan Records
        for(contact con: [SELECT id,accountId FROM contact]){   
            rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlan(con.accountId,false);
            Ap.rC_Bios__WhatId__c = con.Id;
            actionPlans.add(Ap);
        }  
        
        if(!actionPlans.isEmpty())
            insert actionPlans;
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
            
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        // changing the Contact lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        contact con2 = TestUtils.createContact(acc,'firstName2','lastName2',true);
        for(rC_Bios__Action_Plan__c objAp: [SELECT Id FROM rC_Bios__Action_Plan__c ]){
            rC_Bios__Action_Plan__c pre = new rC_Bios__Action_Plan__c();
            pre.Id = objAp.Id;
            pre.rC_Bios__WhatId__c = con2.id;
            actionPlanUpdate.add(pre);
        }
        
        if(!actionPlanUpdate.isEmpty()){
            update actionPlanUpdate;
        }
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        System.assertNotEquals(0, mapGroupNameToId.size());
        
        //Test Delete
        delete actionPlanUpdate;
        System.assertEquals(0, [SELECT Id FROM rC_Bios__Action_Plan__c].size());
        Test.stopTest();
        // check the Previous deleted records
        //List<rC_Bios__Action_Plan__share> apShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Action_Plan__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapActionPlanIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        //system.assertEquals(apShare.size(),0); 
    }
    
    /*
    *Method ActionPlanOpportunityLookupSharingTest 
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void actionPlanOpportunityLookupSharingTest() {
        List<rC_Bios__Action_Plan__c> actionPlans = new List<rC_Bios__Action_Plan__c>();
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapActionPlanIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        List<rC_Bios__Action_Plan__c> actionPlanUpdate = new List<rC_Bios__Action_Plan__c>();
        List<Account> Accounts = [SELECT Id, Affiliation__c, BillingCountry, BillingPostalCode FROM Account];
        List<Opportunity> Opportunities = [SELECT Id, AccountId, CloseDate, StageName FROM Opportunity];
        
        Test.startTest();
        // Action Plan Records
        for(Opportunity opp: [SELECT id,accountId FROM Opportunity]){   
            rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlan(opp.accountId,false);
            Ap.rC_Bios__WhatId__c = opp.Id;
            actionPlans.add(Ap);
        }  
        
        if(!actionPlans.isEmpty())
            insert actionPlans;
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        // changing the Opportunity lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        Opportunity opp= TestUtils.CreateOpportunity(acc.Id, 'Test'+acc.Name, true);
        for(rC_Bios__Action_Plan__c objAp: [SELECT Id FROM rC_Bios__Action_Plan__c ]){
            rC_Bios__Action_Plan__c pre = new rC_Bios__Action_Plan__c();
            pre.Id = objAp.Id;
            pre.rC_Bios__WhatId__c = opp.id;
            actionPlanUpdate.add(pre);
        }
        
        if(!actionPlanUpdate.isEmpty()){
            update actionPlanUpdate;
        }
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        System.assertNotEquals(0, mapGroupNameToId.size());
        
        //Test Delete
        delete actionPlanUpdate;
        System.assertEquals(0, [SELECT Id FROM rC_Bios__Action_Plan__c].size());
        Test.stopTest();
    }
    
    /*
    *Method setup
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    @testSetup
    public static void setup(){
        //Insert Account Records
        List<Account> Accounts = new List<Account>();
        for(Integer i=0;i<2;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            Accounts.add(acc);
        }
        insert Accounts;
        //Insert Account Records
        List<Contact> Contacts = new List<Contact>();
        for(Integer i=0;i<2;i++){   
            Contact con = TestUtils.createContact(Accounts.get(i), 'Test','Contact'+i, false);
            Contacts.add(con);
        }
        insert Contacts;
        //Insert Account Records
        List<Opportunity> Opportunities = new List<Opportunity>();
        for(Integer i=0;i<2;i++) {   
            Opportunity opp = TestUtils.createOpportunity(Accounts.get(i).Id, 'Opportunity'+i, false);
            opp.CloseDate = System.Today();
            opp.StageName = 'Prospecting';
            Opportunities.add(opp);
        }
        insert Opportunities;
    }
}
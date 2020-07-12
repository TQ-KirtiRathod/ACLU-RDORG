/***
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 
 /*
*
*Name  :  RecordAccessUtility_Test
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 15, 2016
*Purpose : Test Class for the RecordAccessUtility class (T-555213)
Updated By: Sandeep Soni
Code Coverage: 87%
*
*/

@isTest
private class RecordAccessUtility_Test {
    public static List<Account> Accounts;
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    
     /*
    *
    *Method resetAccountSharingTest
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    
    static testMethod void resetAccountSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapAccountIdToAffilate = new map<Id,String>();
        setup();
        //insert Trigger
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
        Test.stopTest();
        
        for(Account acc: [SELECT id,Affiliation__c FROM Account ]){
            mapAccountIdToAffilate.put(acc.Id,acc.Affiliation__c);
        }
        for(Group gp: [SELECT id, name FROM group WHERE name=:mapAccountIdToAffilate.values()]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        for(AccountShare accShare: [SELECT Id, AccountAccessLevel, UserOrGroupId, AccountId FROM AccountShare where AccountId =:mapAccountIdToAffilate.keySet() AND AccountAccessLevel = 'Edit']){
            system.assertEquals(accShare.UserOrGroupId,mapGroupNameToId.get(mapAccountIdToAffilate.get(accShare.AccountId)));
        }

        //update Trigger
        for(Account acc: Accounts){
            acc.Affiliation__c = 'FL99';
        }  
    }
    
     /*
    *
    *Method resetAccountSharingUpdateTest
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    static testMethod void resetAccountSharingUpdateTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapAccountIdToAffilate = new map<Id,String>();
        List<AccountShare> accountSharesToInsert = new List<AccountShare>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        
        Test.startTest();
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        if(!accounts.isEmpty())
            insert Accounts;
        for(Account acc: [SELECT id,Affiliation__c FROM Account ]){
            mapAccountIdToAffilate.put(acc.Id,acc.Affiliation__c);
        }
        Contact con = new Contact(LastName='test');
        con.AccountId = Accounts.get(0).id;
        insert con;
        Prospect_Research__c pr = new Prospect_Research__c();
        pr.Account__c = Accounts.get(0).ID;
        pr.Contact__c = con.id;
        insert pr;
        /*for(Account acc: [SELECT id,Affiliation__c FROM Account ]){
            AccountShare accShare = new AccountShare();
            accShare.AccountAccessLevel = 'Edit';
            accShare.ContactAccessLevel = 'Edit';
            accShare.OpportunityAccessLevel = 'Edit';
            // assigns the groupId from AccountId via using the two maps we created above.
            accShare.UserOrGroupId = mapGroupNameToId.get(mapAccountIdToAffilate.get(acc.Id));
            accShare.AccountId = acc.Id;
            accountSharesToInsert.add(accShare);
        }
        if(!accountSharesToInsert.isEmpty())
            insert accountSharesToInsert;*/
        
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();   
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        Test.stopTest();
        
        for(AccountShare accShare: [SELECT Id, AccountAccessLevel, UserOrGroupId, AccountId FROM AccountShare where AccountId =:mapAccountIdToAffilate.keySet() AND AccountAccessLevel = 'Edit']){
            system.assertEquals(accShare.UserOrGroupId,mapGroupNameToId.get('NC')); 
        }
        
        //check the Previous deleted records
        List<AccountShare> accShare = [SELECT Id, AccountAccessLevel, UserOrGroupId, AccountId FROM AccountShare where UserOrGroupId =:mapGroupNameToId.get('NN') AND AccountId =:mapAccountIdToAffilate.keySet() AND AccountAccessLevel = 'Edit'];
        system.assertEquals(accShare.size(),0); 
    }
    
    /*
    *
    *Method resetPreferenceSharingTest
    *Testing if Affiliation on Account updated then PrefereneceShare is re-calculated.
    */
    static testMethod void resetPreferenceSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPrferenceIdToAffilate = new map<Id,String>();
        List<rC_Bios__Preference__share> PreferenceSharesToBeInsert = new List<rC_Bios__Preference__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account]){   
            rC_Bios__Preference__c Pre = TestUtils.CreatePreferences(acc.Id,true);
            mapPrferenceIdToAffilate.put(Pre.Id,acc.Affiliation__c); 
        }  
        
        for(Id ObjId: mapPrferenceIdToAffilate.KeySet()){
            rC_Bios__Preference__share PreShare = new rC_Bios__Preference__share();
            PreShare.ParentId = ObjId;
            PreShare.AccessLevel = 'Edit';
            PreShare.UserOrGroupId = mapGroupNameToId.get(mapPrferenceIdToAffilate.get(ObjId));
            PreferenceSharesToBeInsert.add(PreShare);
        }
        
        if(!PreferenceSharesToBeInsert.IsEmpty())
            insert PreferenceSharesToBeInsert;
        
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where ParentId =:mapPrferenceIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Preference__share> preShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapPrferenceIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(preShare.size(),0); 
    }
    
    /*
    *
    *Method resetRelationShipSharingTest
    *Testing if Affiliation on Account updated then PrefereneceShare is re-calculated.
    */
    static testMethod void resetRelationShipSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapRelationShipIdToAffilate = new map<Id,String>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new map<Id,rC_Bios__Relationship__c>();
        List<rC_Bios__Relationship__share> relationshipSharesToBeInsert = new List<rC_Bios__Relationship__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
  
        // Preference Records
        Contact con = new Contact(lastname='test12');
        con.AccountId = Accounts[0].Id;
        insert con;
        
        Opportunity opp= TestUtils.CreateOpportunity(Accounts[0].Id, 'Test11', true);
        Confidential_Data__c cd = new Confidential_Data__c();
        cd.Contact__c = con.id;
        cd.Account__c = Accounts[0].id;
        cd.Opportunity__c= opp.id;
        insert cd;
        rC_Bios__Relationship__c RS = TestUtils.CreateRelationShip(Accounts[0].Id, Accounts[1].Id, false);
        Accounts[0].Restricted_Account__c= true;
        Accounts[0].Affiliation__c = 'AA';
        update Accounts[0];
        RS.rC_Bios__Contact_1__c = con.id; 
        RS.rC_Bios__Contact_2__c = con.id;
        RS.rC_Bios__Account_1__c = Accounts[0].Id;
        RS.rC_Bios__Account_2__c = Accounts[0].Id;
        RS.rC_Bios__Opportunity__c = opp.id;
        insert RS;
        mapRelationShipIdToAffilate.put(RS.Id,Accounts[0].Affiliation__c); 
        mapRelationshipIdToRelationship.put(Rs.Id,Rs);
        
        for(Id objId: mapRelationShipIdToAffilate.KeySet()){
            //Accounts
            if(mapRelationshipIdToRelationship.get(ObjId) != null && mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_1__r.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_1__r.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_1__r.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }
            
            if(mapRelationshipIdToRelationship.get(ObjId) != null && mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_2__r.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_2__r.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_2__r.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }
        }
        
        if(!relationshipSharesToBeInsert.IsEmpty())
            insert relationshipSharesToBeInsert;
        
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun(); 
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(RSShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Relationship__share> reShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(reShare.size(),0); 
    }
    
    /*
    *
    *Method resetPaymentMethodSharingTest
    *Testing if Affiliation on Account updated then PaymentMethod Share is re-calculated.
    */
    static testMethod void resetPaymentMethodSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPaymentMethodIdToAffilate = new map<Id,String>();
        List<rC_Giving__Payment_Method__share> PaymentMethodSharesToBeInsert = new List<rC_Giving__Payment_Method__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
         for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account]){   
            rC_Giving__Payment_Method__c PM = TestUtils.CreatePaymentMethod(acc.Id,true);
            mapPaymentMethodIdToAffilate.put(PM.Id,acc.Affiliation__c); 
        }  
        
        for(Id objId: mapPaymentMethodIdToAffilate.Keyset()){
            rC_Giving__Payment_Method__share PmShare = new rC_Giving__Payment_Method__share();
            PmShare.ParentId = ObjId;
            PmShare.AccessLevel = 'Edit';
            PmShare.UserOrGroupId = mapGroupNameToId.get(mapPaymentMethodIdToAffilate.get(ObjId));
            PaymentMethodSharesToBeInsert.add(PmShare);
        }
        
        if(!PaymentMethodSharesToBeInsert.IsEmpty())
            insert PaymentMethodSharesToBeInsert;
        //reset accounttriggerhanler recursive variable
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Giving__Payment_Method__share pmShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Payment_Method__share where ParentId =:mapPaymentMethodIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(pmShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        //check the Previous deleted records
        List<rC_Giving__Payment_Method__share> pmShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Payment_Method__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapPaymentMethodIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(pmShare.size(),0); 
    }
    
    
    static testMethod void resetPaymentMethodSharingTest1() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPaymentMethodIdToAffilate = new map<Id,String>();
        List<rC_Giving__Payment_Method__share> PaymentMethodSharesToBeInsert = new List<rC_Giving__Payment_Method__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        //Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        
        User u = new User(Id=Userinfo.getUserId(),Is_Affiliate_User__c=False);
        System.runAs(u){Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
         for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account]){   
            rC_Giving__Payment_Method__c PM = TestUtils.CreatePaymentMethod(acc.Id,true);
            mapPaymentMethodIdToAffilate.put(PM.Id,acc.Affiliation__c); 
        }  
        
        for(Id objId: mapPaymentMethodIdToAffilate.Keyset()){
            rC_Giving__Payment_Method__share PmShare = new rC_Giving__Payment_Method__share();
            PmShare.ParentId = ObjId;
            PmShare.AccessLevel = 'Edit';
            PmShare.UserOrGroupId = mapGroupNameToId.get(mapPaymentMethodIdToAffilate.get(ObjId));
            PaymentMethodSharesToBeInsert.add(PmShare);
        }
        
        if(!PaymentMethodSharesToBeInsert.IsEmpty())
            insert PaymentMethodSharesToBeInsert;
        
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Giving__Payment_Method__share pmShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Payment_Method__share where ParentId =:mapPaymentMethodIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(pmShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        //check the Previous deleted records
        List<rC_Giving__Payment_Method__share> pmShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Payment_Method__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapPaymentMethodIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(pmShare.size(),0); }
        
    }
    
    /*
    *
    *Method resetSalutationSharingTest
    *Testing if Affiliation on Account updated then Salutation Share is re-calculated.
    */
    static testMethod void resetSalutationSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapSalutationIdToAffilate = new map<Id,String>();
        List<rC_Bios__Salutation__share> SalutationSharesToBeInsert = new List<rC_Bios__Salutation__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Salutation Records
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account]){   
            rC_Bios__Salutation__c Sl = TestUtils.CreateSalutation(acc.Id,true);
            mapSalutationIdToAffilate.put(Sl.Id,acc.Affiliation__c); 
        }  
        
        for(Id objId: mapSalutationIdToAffilate.KeySet()){
            rC_Bios__Salutation__share SalShare = new rC_Bios__Salutation__share();
            SalShare.ParentId = ObjId;
            SalShare.AccessLevel = 'Edit';
            SalShare.UserOrGroupId = mapGroupNameToId.get(mapSalutationIdToAffilate.get(ObjId));
            SalutationSharesToBeInsert.add(SalShare);
        }
        
        if(!SalutationSharesToBeInsert.IsEmpty())
            insert SalutationSharesToBeInsert;
        
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Bios__Salutation__share slShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where ParentId =:mapSalutationIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(slShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        // check the Previous deleted records
        List<rC_Bios__Salutation__share> salShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapSalutationIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(salShare.size(),0); 
    }
    
    /*
    *
    *Method resetPlannedGivingSharingTest
    *Testing if Affiliation on Account updated then PlannedGiving Share is re-calculated.
    */
    
    static testMethod void resetPlannedGivingSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPlannedGivingIdToAffilate = new map<Id,String>();
        Map<Id,rC_Giving__Planned_Giving__c> mapPlannedGivingIdToPlannedGiving = new map<Id,rC_Giving__Planned_Giving__c>();
        List<rC_Giving__Planned_Giving__share> PlannedGivingSharesToBeInsert = new List<rC_Giving__Planned_Giving__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Planned Giving Records
        rC_Giving__Planned_Giving__c RS = TestUtils.CreatePlannedGiving(Accounts[0].Id, Accounts[1].Id, true);
        mapPlannedGivingIdToAffilate.put(RS.Id,Accounts[0].Affiliation__c); 
        mapPlannedGivingIdToPlannedGiving.put(Rs.Id,Rs);
         
        for(Id objId: mapPlannedGivingIdToPlannedGiving.KeySet()){
            if(mapPlannedGivingIdToPlannedGiving.get(ObjId) != null && mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Account__r.Affiliation__c != null && mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Account__r.Affiliation__c) != null){
                rC_Giving__Planned_Giving__share PGShare = new rC_Giving__Planned_Giving__share();
                PGShare.ParentId = ObjId;
                PGShare.AccessLevel = 'Edit';
                PGShare.UserOrGroupId = mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Account__r.Affiliation__c);
                PlannedGivingSharesToBeInsert.add(PGShare);
            }
            
            if(mapPlannedGivingIdToPlannedGiving.get(ObjId) != null && mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Fund__r.Affiliation__c != null && mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Fund__r.Affiliation__c) != null){
                rC_Giving__Planned_Giving__share PGShare = new rC_Giving__Planned_Giving__share();
                PGShare.ParentId = ObjId;
                PGShare.AccessLevel = 'Edit';
                PGShare.UserOrGroupId = mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Fund__r.Affiliation__c);
                PlannedGivingSharesToBeInsert.add(PGShare);
            }
        }
        
        if(!PlannedGivingSharesToBeInsert.IsEmpty())
            insert PlannedGivingSharesToBeInsert;
        
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Giving__Planned_Giving__share GpShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Planned_Giving__share where ParentId =:mapPlannedGivingIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(GpShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        // check the Previous deleted records
        List<rC_Giving__Planned_Giving__share> pgShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Planned_Giving__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapPlannedGivingIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(pgShare.size(),0); 
    }
    
    /*
    *
    *Method resetActionPlanSharingTest
    *Testing if Affiliation on Account updated then ActionPlan Share is re-calculated.
    */
    
    /*static testMethod void resetActionPlanSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapActionPlanIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        //List<rC_Bios__Action_Plan__share> ActionPlanSharesToBeInsert = new List<rC_Bios__Action_Plan__share>(); 
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        // ActionPlan Records
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account]){   
            rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlan(acc.Id,true);
            mapActionPlanIdToAffilate.put(Ap.Id,acc.Affiliation__c); 
        }
          
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        //for(Id objId: mapActionPlanIdToAffilate.keySet() ){
        //    rC_Bios__Action_Plan__share AcPShare = new rC_Bios__Action_Plan__share();
        //    AcPShare.ParentId = ObjId;
        //    AcPShare.AccessLevel = 'Edit';
        //    AcPShare.UserOrGroupId = mapGroupNameToId.get(mapActionPlanIdToAffilate.get(ObjId));
        //    ActionPlanSharesToBeInsert.add(AcPShare);
        //}
        //if(!ActionPlanSharesToBeInsert.IsEmpty())
        //    insert ActionPlanSharesToBeInsert;
        
        ////resetting the accountTriggerHandler trigger
        //AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        ////update Trigger
        //for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
        //    acc.Affiliation__c = 'NC';
        //    AccountsToBeUpdate.add(acc);
        //}
        //update AccountsToBeUpdate;
        
        //Test.stopTest();
        
        //for(rC_Bios__Action_Plan__share ApShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Action_Plan__share where ParentId =:mapActionPlanIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
        //    system.assertEquals(ApShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        //}
        
        //// check the Previous deleted records
        //List<rC_Bios__Action_Plan__share> apShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Action_Plan__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapActionPlanIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        //system.assertEquals(apShare.size(),0);
    }*/
    
    /*
    *
    *Method resetActionPlanSharingUnderContactsTest
    *Testing if Affiliation on Account updated then ActionPlan Share is re-calculated.
    */
    
    static testMethod void resetActionPlanSharingUnderContactsTest() {
        List<Contact> contacts = new List<Contact>();
        List<rC_Bios__Action_Plan__c> actionPlans = new List<rC_Bios__Action_Plan__c>();
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapActionPlanIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
           
        for(Account acc: accounts){
            contact con= TestUtils.createContact(acc,'firstName2','lastName2',true);
            contacts.add(con);
        }
          
        // Action Plan Records
        for(Contact con: [SELECT Id,AccountId FROM Contact]){   
            rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlan(con.accountId,false);
            Ap.rC_Bios__Account__c = Accounts.get(0).id;
            Ap.rC_Bios__WhatId__c = con.Id;
            actionPlans.add(Ap);
        }  
        
        if(!actionPlans.isEmpty())
            insert actionPlans;

        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        /*for(rC_Bios__Action_Plan__share share: [SELECT Id, UserOrGroupId, AccessLevel, ParentId FROM rC_Bios__Action_Plan__share where AccessLevel = 'Edit' AND ParentId =:actionPlans AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(share.UserOrGroupId,mapGroupNameToId.get('NC'));
        }*/
    }
    
    /*
    *
    *Method resetPreferenceSharingUnderContactsTest
    *Testing if Affiliation on Account updated then Prefereneces which are lookup to contact's Account  records share is re-calculated.
    */
    
    static testMethod void resetPreferenceSharingUnderContactsTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPrferenceIdToAffilate = new map<Id,String>();
        List<rC_Bios__Preference__c> preferenceRecordsToBeInsert = new List<rC_Bios__Preference__c>(); 
        List<rC_Bios__Preference__share> PreferenceSharesToBeInsert = new List<rC_Bios__Preference__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<Contact> contacts = new List<Contact>();
        setup();
        
        if(!accounts.isEmpty())
            insert Accounts;
        Accounts.get(0).Restricted_Account__c = true;

        update Accounts.get(0);
        for(Account acc: accounts){
            contact con= new contact(AccountId = acc.Id,lastName = 'Test'+acc.Name);
            contacts.add(con);
        }
        
        if(!contacts.isEmpty())
            insert contacts;
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        for(Contact con: [SELECT Id,AccountId FROM Contact]){   
            rC_Bios__Preference__c Pre = TestUtils.CreatePreferences(con.accountId,false);
            Pre.rC_Bios__Account__c = con.accountId;
            Pre.rC_Bios__Contact__c = con.Id;
            preferenceRecordsToBeInsert.add(Pre);
             
        }  
        
        if(!preferenceRecordsToBeInsert.IsEmpty())
            insert preferenceRecordsToBeInsert;
        
        Test.startTest();
        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        Test.stopTest();
        
        for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share 
                                                  where ParentId =:preferenceRecordsToBeInsert 
                                                  AND AccessLevel = 'Edit' 
                                                  AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
   
        //check the Previous deleted records
        List<rC_Bios__Preference__share> preShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share 
                                                     where UserOrGroupId =:mapGroupNameToId.get('NN') 
                                                     AND ParentId =:preferenceRecordsToBeInsert 
                                                     AND AccessLevel = 'Edit'];
        system.assertEquals(preShare.size(),0); 
    }
    
    
    /*
    *
    *Method resetSalutationSharingUnderContactsTest
    *Testing if Affiliation on Account updated then Prefereneces which are lookup to contact's Account  records share is re-calculated.
    */
    
    static testMethod void resetSalutationSharingUnderContactsTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapSalutationIdToAffilate = new map<Id,String>();
        List<rC_Bios__Salutation__c> SalutationRecordsToBeInsert = new List<rC_Bios__Salutation__c>(); 
        List<rC_Bios__Salutation__share> SalutationSharesToBeInsert = new List<rC_Bios__Salutation__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<Contact> contacts = new List<Contact>();
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
        Accounts.get(0).Restricted_Account__c = true;
        update Accounts.get(0);
        for(Account acc: accounts){
            contact con= new contact(AccountId = acc.Id,lastName = 'Test'+acc.Name);
            contacts.add(con);
        }
        
        if(!contacts.isEmpty())
            insert contacts;
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        for(Contact con: [SELECT Id,AccountId FROM Contact]){   
            rC_Bios__Salutation__c Pre = TestUtils.CreateSalutation(con.accountId,false);
            Pre.rC_Bios__Account__c = Accounts.get(0).id;
            Pre.rC_Bios__Contact__c = con.Id;
            SalutationRecordsToBeInsert.add(Pre);
             
        }  
        
        if(!SalutationRecordsToBeInsert.IsEmpty())
            insert SalutationRecordsToBeInsert;

        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(rC_Bios__Salutation__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where ParentId =:SalutationRecordsToBeInsert AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('NC'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Salutation__share> preShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:SalutationRecordsToBeInsert AND AccessLevel = 'Edit'];
        system.assertEquals(preShare.size(),0); 
    } 
 
    /*
    *
    *Method resetActionPlanSharingUnderOpportunityTest
    *Testing if Affiliation on Account updated then ActionPlan Share is re-calculated.
    */
    
    static testMethod void resetActionPlanSharingUnderOpportunityTest() {
        List<Opportunity> opportunities = new List<Opportunity>();
        List<rC_Bios__Action_Plan__c> actionPlans = new List<rC_Bios__Action_Plan__c>();
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapActionPlanIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
           
        for(Account acc: accounts){
            Opportunity opp= TestUtils.CreateOpportunity(acc.Id, 'Test'+acc.Name, true);
            opportunities.add(opp);
        }
            
        // Action Plan Records
        for(Opportunity Opp: [SELECT Id,accountId FROM Opportunity]){   
            rC_Bios__Action_Plan__c Ap = TestUtils.CreateActionPlan(opp.accountId,false);
            Ap.rC_Bios__Account__c = null;
            Ap.rC_Bios__WhatId__c = opp.Id;
            actionPlans.add(Ap);
        }  
        
        if(!actionPlans.isEmpty())
            insert actionPlans;

        //resetting the accountTriggerHandler trigger
        AccountTriggerHandler.resetRecordAccessUtilityHasRun();
         //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'NC';
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        Test.stopTest();
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        /*for(rC_Bios__Action_Plan__share share: [SELECT Id, UserOrGroupId, AccessLevel, ParentId FROM rC_Bios__Action_Plan__share where AccessLevel = 'Edit' AND ParentId =:actionPlans AND UserOrGroupId =:mapGroupNameToId.get('NC')]){
            system.assertEquals(share.UserOrGroupId,mapGroupNameToId.get('NC'));
        }*/
    }
    
    /*@isTest
    public static void testResetConfidential(){
        test.startTest();
        userRole r= new userrole(developername='test5',name='test');
        insert r;
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Create new user with a non-null user role ID 
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',r.Id,false);
        u.ProfileId=p.id; 
        u.Is_Affiliate_User__c=false;
        /*User u = [SELECT id, Is_Affiliate_User__c from USER WHERE Id =: UserInfo.getUserId()];
        u.Is_Affiliate_User__c = false;

        update u;
        test.stopTest();
    }*/
    
    /*
    *
    *Method setup
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    public static void setup(){
        Accounts = new List<Account>();
        
        // Account Records
        for(Integer i=0;i<2;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.RecordTypeId = houseHoldId;
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            Accounts.add(acc);
        }     
    }


    @ISTEST
    public static void hasCreatePermissiontest(){
        List<String> affiliations = new List<String>();
        affiliations.add('test1');
        affiliations.add('test2');
        affiliations.add('test3');
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'Solution Manager' Limit 1];
        UserRole ur = new UserRole(name='testrole');
        insert ur;
        User user = TestUtils.createUser('test', 'test43433@gmail.com', ur.id, false);
        user.Is_Affiliate_User__c=False;
        user.ProfileId = adminProfile.id;
        insert user;
        
        User user1 = TestUtils.createUser('test', 'test433@gmail.com', ur.id, false);
        user1.Is_Affiliate_User__c=true;
        user1.ProfileId = adminProfile.id;
        insert user1;
        System.debug('affiliation::'+affiliations);
        User u = [SELECT id, Is_Affiliate_User__c from USER WHERE ProfileId=:adminProfile.id limit 1];

        System.runas(u){
            map<String, Boolean> result = RecordAccessUtility.hasCreatePermission(affiliations);
            system.assertEquals(true, result.get('test1'));
            system.assertEquals(true, result.get('test2'));
            system.assertEquals(true, result.get('test3'));
        }
        Group grp = new Group(name='test1');
        insert grp;
        GroupMember gm = new GroupMember();  
        gm.GroupId = grp.id;
        gm.UserOrGroupId = user1.id;
        insert gm;
        System.runas(user1){
            RecordAccessUtility.hasCreatePermission(affiliations);
        }
    }

}
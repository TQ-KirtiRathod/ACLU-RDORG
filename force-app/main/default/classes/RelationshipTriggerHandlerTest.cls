/**
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
*Name  :  RelationshipTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 23, 2016
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
private class RelationshipTriggerHandlerTest {
	public static List<Account> Accounts;
	/*
    *
    *Method RelationshipAccountLookupSharingTest 
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void RelationshipAccountLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapRelationShipIdToAffilate = new map<Id,String>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new map<Id,rC_Bios__Relationship__c>();
        List<rC_Bios__Relationship__share> relationshipSharesToBeInsert = new List<rC_Bios__Relationship__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Bios__Relationship__c> relationshipUpdate = new List<rC_Bios__Relationship__c>();
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        system.debug('mapGroup:>>>>>>>>>>:::::;'+mapGroupNameToId);    
        // Preference Records
         
        rC_Bios__Relationship__c RS = TestUtils.CreateRelationShip(Accounts[0].Id, Accounts[1].Id, true);
        mapRelationShipIdToAffilate.put(RS.Id,Accounts[0].Affiliation__c); 
        mapRelationshipIdToRelationship.put(Rs.Id,Rs);
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
         // changing the Payment account lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        Account acc1 = TestUtils.createAccount('Account'+1,true);
        
        for(Id objId: mapRelationshipIdToRelationship.KeySet()){
        	rC_Bios__Relationship__c pre = new rC_Bios__Relationship__c();
        	pre.Id = objId;
        	pre.rC_Bios__Account_1__c = acc.id;
        	pre.rC_Bios__Account_2__c = acc1.id;
        	relationshipUpdate.add(pre);
        }
        
        if(!relationshipUpdate.isEmpty()){
        	update relationshipUpdate;
        }
        
        Test.stopTest();
        
        for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
            system.assertEquals(RSShare.UserOrGroupId,mapGroupNameToId.get('NN'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Relationship__share> reShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(reShare.size(),0); 
        
    }
    
    /*
    *
    *Method RelationshipPrivateAccountLookupSharingTest 
    *Testing if Relationship record created then share is not created based as it is private account & .
    */
    static testMethod void RelationshipPrivateAccountLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapRelationShipIdToAffilate = new map<Id,String>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new map<Id,rC_Bios__Relationship__c>();
        List<rC_Bios__Relationship__share> relationshipSharesToBeInsert = new List<rC_Bios__Relationship__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Bios__Relationship__c> relationshipUpdate = new List<rC_Bios__Relationship__c>();
        setup();
        
        Test.startTest();
         if(!accounts.isEmpty())
            insert Accounts;
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        system.debug('mapGroup:>>>>>>>>>>:::::;'+mapGroupNameToId);    
        // Preference Records
         
        rC_Bios__Relationship__c RS = TestUtils.CreateRelationShip(Accounts[0].Id, Accounts[1].Id, true);
        mapRelationShipIdToAffilate.put(RS.Id,Accounts[0].Affiliation__c); 
        mapRelationshipIdToRelationship.put(Rs.Id,Rs);
        
        Account acc = TestUtils.createAccount('Account',false);
        acc.Restricted_Account__c = true;
        insert acc;
        
        RS.rC_Bios__Account_1__c = acc.Id;
        update RS;
        
        update accounts;
        
        
        
        Test.stopTest();
        
        //check the Previous deleted records
        List<rC_Bios__Relationship__share> reShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(reShare.size(),0); 
        
    }
    
    /*
    *
    *Method RelationshipcontactLookupSharingTest 
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void RelationshipcontactLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapRelationShipIdToAffilate = new map<Id,String>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new map<Id,rC_Bios__Relationship__c>();
        List<rC_Bios__Relationship__share> relationshipSharesToBeInsert = new List<rC_Bios__Relationship__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Bios__Relationship__c> relationshipUpdate = new List<rC_Bios__Relationship__c>();
        List<contact> contacts = new List<Contact>();
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Account acc: Accounts){
        	contacts.add(TestUtils.createContact(acc,'firstName1','lastName1',true));
        }
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        system.debug('mapGroup:>>>>>>>>>>:::::;'+mapGroupNameToId);    
        // Preference Records
         
        rC_Bios__Relationship__c RS = TestUtils.CreateRelationShipUsingContact(contacts[0].Id, contacts[1].Id, true);
        mapRelationShipIdToAffilate.put(RS.Id,Accounts[0].Affiliation__c); 
        mapRelationshipIdToRelationship.put(Rs.Id,Rs);
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
         // changing the Payment account lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        Account acc1 = TestUtils.createAccount('Account'+1,true);
        contact con1 = TestUtils.createContact(acc,'firstName1','lastName1',true);
        contact con2 = TestUtils.createContact(acc1,'firstName2','lastName2',true);
        
        for(Id objId: mapRelationshipIdToRelationship.KeySet()){
        	rC_Bios__Relationship__c pre = new rC_Bios__Relationship__c();
        	pre.Id = objId;
        	pre.rC_Bios__Contact_1__c = con1.id;
        	pre.rC_Bios__Contact_2__c = con2.id;
        	relationshipUpdate.add(pre);
        }
        
        if(!relationshipUpdate.isEmpty()){
        	update relationshipUpdate;
        }
        
        Test.stopTest();
        
        for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
            system.assertEquals(RSShare.UserOrGroupId,mapGroupNameToId.get('NN'));
        }
        
        //check the Previous deleted records
        List<rC_Bios__Relationship__share> reShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Relationship__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapRelationShipIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(reShare.size(),0); 
        
    }
    
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
            acc.Affiliation__c = 'NN';
            Accounts.add(acc);
        }   
    }
}
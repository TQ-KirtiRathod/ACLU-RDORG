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
*Name  :  salutationTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 23, 2016
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
private class salutationTriggerHandlerTest {
    public static List<Account> Accounts;
    public Static Contact con;
    public static List<rC_Bios__Salutation__c> listSalutations;
    /*
*
*Method salutationAccountLookupSharingTest 
*Testing if preference record created then share is created based on related affiliate.
*/
    static testMethod void salutationAccountLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapSalutationIdToAffilate = new map<Id,String>();
        List<rC_Bios__Salutation__share> SalutationSharesToBeInsert = new List<rC_Bios__Salutation__share>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        List<rC_Bios__Salutation__c> saluatationsUpdate = new List<rC_Bios__Salutation__c>();  
        
        setup();
        
        Test.startTest();
        /* if(!accounts.isEmpty())
insert Accounts; */
        // Create and Insert Salutation object
        rC_Bios__Salutation__c slu = TestUtils.createSalutation(Accounts[0].Id,true);
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        // Salutation Records
        for(Account acc: [SELECT id,Affiliation__c FROM Account]){   
            rC_Bios__Salutation__c Sl = TestUtils.CreateSalutation(acc.Id,true);
            mapSalutationIdToAffilate.put(Sl.Id,acc.Affiliation__c); 
        }  
        
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
            
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        // changing the Salutation account lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        acc.Affiliation__c = 'DC';
        acc.Restricted_Account__c = False;
        update acc;
        
        
        for(Id objId: mapSalutationIdToAffilate.Keyset()){
            rC_Bios__Salutation__c pre = new rC_Bios__Salutation__c();
            pre.Id = objId;
            pre.rC_Bios__Account__c = acc.id;
            pre.rC_Bios__Contact__c = con.id;
            
            saluatationsUpdate.add(pre);
        }
        
        if(!saluatationsUpdate.isEmpty()){
            upsert saluatationsUpdate;
        }
        
        if(!saluatationsUpdate.isEmpty()){
            delete saluatationsUpdate;
        } 
        
        Test.stopTest();
        
        for(rC_Bios__Salutation__share slShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where ParentId =:mapSalutationIdToAffilate.keySet() AND AccessLevel = 'Edit']){
            system.assertEquals(slShare.UserOrGroupId,mapGroupNameToId.get('NN'));
        }
        
        // check the Previous deleted records
        List<rC_Bios__Salutation__share> salShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Salutation__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapSalutationIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(salShare.size(),0); 
        
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
        insert Accounts;
        
        //Contact Records
        con = TestUtils.createContact(Accounts[0],'cons'+1,'testPhone'+1,false);
        insert con; 
        
    }
}
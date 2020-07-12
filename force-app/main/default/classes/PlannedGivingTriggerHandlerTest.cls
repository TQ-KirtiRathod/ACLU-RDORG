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
*Name  :  PlannedGivingTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 23, 2016
*Purpose : Reset the shareing for the lookups changes
Code Coverage: 96%
*
*/
@isTest
private class PlannedGivingTriggerHandlerTest {
    public static List<Account> Accounts;
    /*
    *
    *Method PlannedGivingAccountLookupSharingTest 
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void plannedGivingAccountLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPlannedGivingIdToAffilate = new map<Id,String>();
        Map<Id,rC_Giving__Planned_Giving__c> mapPlannedGivingIdToPlannedGiving = new map<Id,rC_Giving__Planned_Giving__c>();
        List<rC_Giving__Planned_Giving__share> PlannedGivingSharesToBeInsert = new List<rC_Giving__Planned_Giving__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Giving__Planned_Giving__c> PlannedGivingUpdate = new List<rC_Giving__Planned_Giving__c>();
        List<rC_Giving__Planned_Giving__c> PlannedGivingToDelete = new List<rC_Giving__Planned_Giving__c>();
        
        setup();
        
        Test.startTest();
        if(!accounts.isEmpty())
            insert Accounts;
            
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        rC_Giving__Planned_Giving__c RS = TestUtils.CreatePlannedGiving(Accounts[0].Id, Accounts[1].Id, true);
        mapPlannedGivingIdToAffilate.put(RS.Id,Accounts[0].Affiliation__c); 
        mapPlannedGivingIdToPlannedGiving.put(Rs.Id,Rs);
        
        //update Trigger
        for(Account acc: [SELECT Id,Affiliation__c,BillingPostalCode FROM Account] ){
            acc.Affiliation__c = 'ZF';
           
            AccountsToBeUpdate.add(acc);
        }
        update AccountsToBeUpdate;
        
        // changing the Payment account lookup .
        Account acc = TestUtils.createAccount('Account'+1,true);
        Account acc1 = TestUtils.createAccount('Account'+1,true);
        for(Id objId: mapPlannedGivingIdToPlannedGiving.KeySet()){
            rC_Giving__Planned_Giving__c pre = new rC_Giving__Planned_Giving__c();
            pre.Id = objId;
            pre.rC_Giving__Account__c = acc.id;
            pre.rC_Giving__Fund__c = acc1.id;
            PlannedGivingUpdate.add(pre);
            PlannedGivingToDelete.add(pre);
        }
        
        if(!PlannedGivingUpdate.isEmpty()){
            update PlannedGivingUpdate;
        }
        
        
        if(!PlannedGivingToDelete.isEmpty()){
        Database.DeleteResult[] result = Database.delete(PlannedGivingToDelete, false);
        //rC_Giving__Planned_Giving__c plannedGivingDelete = [SELECT Id, IsDelete From rC_Giving__Planned_Giving__c WHERE Id IN : mapPlannedGivingIdToPlannedGiving.KeySet() ALL ROWS];
        //System.asserEquals(deletedAccount.IsDeleted, true);    
       } 
        
        Database.UnDeleteResult[] result = Database.unDelete(PlannedGivingToDelete,false);
        
        Test.stopTest();
        
        for(rC_Giving__Planned_Giving__share GpShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Planned_Giving__share where ParentId =:mapPlannedGivingIdToAffilate.keySet() AND AccessLevel = 'Edit' AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
            system.assertEquals(GpShare.UserOrGroupId,mapGroupNameToId.get('NN'));
        }    
        
        // check the Previous deleted records
        List<rC_Giving__Planned_Giving__share> pgShare = [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Giving__Planned_Giving__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapPlannedGivingIdToAffilate.keySet() AND AccessLevel = 'Edit'];
        system.assertEquals(pgShare.size(),0); 
        
    }
    
    /*
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
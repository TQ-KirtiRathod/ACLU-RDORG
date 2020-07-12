/***********************************************************************************************************
* Appirio, Inc
* Name         : AccountConstituentUpdaterTest
* Created By   : Harshita Gupta
* Purpose      : Test class for AccountConstituentUpdater class
* Created Date : June 26,2017
*
* Date Modified                Modified By             Description of the update
**********************************************************************************************************/

@isTest
private class AccountConstituentUpdaterTest {
    
    private static testMethod void testAccountConstituentUpdater(){
        List<Account> accList = new List<Account>();
        List<Contact> conList = new List<Contact>();
        accList = TestUtils.createAccounts(true);
        
        for(integer i=0; i<9; i++){
            Contact con = TestUtils.createContact(accList.get(Math.mod(i, 3)),'testCon'+i,'testCon'+i,false);
            conList.add(con);
        }
        insert conList;
        
        User sysAdmin = TestUtils.createSysAdminUser('System Administrator');
        insert sysAdmin;
        // Creating new campaign as sys admin
         Campaign testCampaign1 = new Campaign();
        System.runAs(sysAdmin){
            testCampaign1 = TestUtils.createCampaign('testCampaign1', false);
            testCampaign1.rC_Giving__Source_Code__c = 'givingSourceCode';
            insert testCampaign1;
        }
        
        // Creating opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        for(integer i=0; i<10; i++){
            Opportunity tempOpp = TestUtils.createOpportunity(accList.get(0).Id,'testOpp'+i,false);
            tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
            tempOpp.CampaignId = testCampaign1.Id;
            //            tempOpp.Restriction__c = '2NDAMENDC3 - Second Amendment C3 (156)';
            oppList.add(tempOpp);
        }
        System.debug('oppList::'+oppList);
        if(oppList.size()>0){
            insert oppList;
        }
        
        // Creating sb_action__c record
        sb_action__c testAction1 = new sb_action__c();
        testAction1.name = 'testAction1';
        insert testAction1;
        
        // Creating child record(sb_Actions_Taken__c) for sb_action__c
        sb_Actions_Taken__c acTaken = new sb_Actions_Taken__c();
        acTaken.Campaign__c = testCampaign1.Id;
        acTaken.Contact__c = conList.get(0).Id;
        acTaken.Action__c = testAction1.Id;
        insert acTaken;
        
        accList = [SELECT id,Acquisition_Source__c,(SELECT id FROM Contacts) FROM Account];
        List<Account> returnedAccList = AccountConstituentUpdater.updateAcquisitonSourceOnAccounts(accList);
        System.assertEquals(10, returnedAccList.size());
    }
    
    
}
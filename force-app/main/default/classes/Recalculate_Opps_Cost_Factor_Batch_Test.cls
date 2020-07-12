/*
*Name  :  Recalculate_Opps_Cost_Factor_Batch_Test
*Author:  Appirio India (Gagandeep Kaur)
*Purpose : Test Call for Recalculate_Opps_Cost_Factor_Batch
*
*/
@isTest
private class Recalculate_Opps_Cost_Factor_Batch_Test {
    static Campaign c;
    static testMethod void testBatch() {
        Test.StartTest();   
        createTestData();   
        Recalculate_Opps_Cost_Factor_Batch.updateCostFactor(c.Id);
        Test.stopTest();
        list<Campaign> cList = [SELECT Id,Actual_Cost_Factor__c,Exclude_Cost_Factors_in_RevShare__c, (SELECT Id, Name,Cost_Factor__c, Exclude_Cost_Factors_in_RevShare__c,
                                                                                                      Recalculate_Revenue_Share__c FROM Opportunities) FROM Campaign WHERE Id = :c.Id ];
        for(Campaign cm : cList) {
            for(Opportunity op : cm.Opportunities) {
                system.assertEquals(op.Cost_Factor__c, cm.Actual_Cost_Factor__c);
                system.assertEquals(true, op.Recalculate_Revenue_Share__c);
                system.assertEquals(op.Exclude_Cost_Factors_in_RevShare__c, cm.Exclude_Cost_Factors_in_RevShare__c);
            }
        }
    }
    
    static testMethod void testBatch_ACLU_User() {
        Test.StartTest();   
        createTestData();  
        User us = TestUtils.createUser('Test','testUser000@acluco.org',null,false);
        us.ProfileId = [SELECT Id FROM Profile WHERE Name = 'ACLU Constituent Management'].Id;
        us.Email = 'testUser000@aclu-co.org';
        insert us;
        CampaignShare cs = TestUtils.createCampaignShare(c.Id, us.Id, 'Edit', true);
        system.runAs(us) { 
            Recalculate_Opps_Cost_Factor_Batch.updateCostFactor(c.Id);
        }
        Test.stopTest();
        list<Campaign> cList = [SELECT Id,Actual_Cost_Factor__c,Exclude_Cost_Factors_in_RevShare__c, (SELECT Id, Name,Cost_Factor__c, Exclude_Cost_Factors_in_RevShare__c,
                                                                                                      Recalculate_Revenue_Share__c FROM Opportunities) FROM Campaign WHERE Id = :c.Id ];
        for(Campaign cm : cList) {
            for(Opportunity op : cm.Opportunities) {
                system.assertEquals(op.Cost_Factor__c, cm.Actual_Cost_Factor__c);
                system.assertEquals(true, op.Recalculate_Revenue_Share__c);
                system.assertEquals(op.Exclude_Cost_Factors_in_RevShare__c, cm.Exclude_Cost_Factors_in_RevShare__c);
            }
        }
    }
    static testMethod void testBatch_Group_User() {
        Test.StartTest();
        User sysAdmin = [SELECT Id FROM User WHERE Id = :userInfo.getUserId()];
        User us;
        system.runAs(sysAdmin) {
            us = TestUtils.createUser('Test','testUser000@acluco.org',null,false);
            us.ProfileId = [SELECT Id FROM Profile WHERE Name = 'ACLU Constituent Management'].Id;
            us.Email = 'testUser000@aclu-co.org';
            insert us;
            createTestData(); 
            Group g = TestUtils.createGroup('AK', true);
            GroupMember gm = TestUtils.createGroupmember(us.Id, g.Id, true);
            
            CampaignShare cs = TestUtils.createCampaignShare(c.Id, g.Id, 'Edit', true);
        }
        system.runAs(us) { 
            Recalculate_Opps_Cost_Factor_Batch.updateCostFactor(c.Id);
        }
        Test.stopTest();
        System.assertEquals(True, [Select id, Recalculate_Revenue_Share__c FROM opportunity LIMIT 1].Recalculate_Revenue_Share__c);
        System.assertEquals(False, [Select id, Exclude_Cost_Factors_in_RevShare__c FROM opportunity LIMIT 1].Exclude_Cost_Factors_in_RevShare__c);
    } 
    static void createTestData() {
        User usr = TestUtils.createUser('usertest123','usertest1@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest1456@aclu.org';
        insert usr;
        System.runAs(usr){
            c= TestUtils.createCampaign('TestCampaign', false);
            c.Exclude_Cost_Factors_in_RevShare__c = false;
            c.ActualCost = 420.20;
            c.rC_Giving__Source_Code__c = '001';
            insert c;
        }    
        
        //Campaign Share Records
        Account acc = TestUtils.createAccount('testAccount', true);
        Id OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        list<Opportunity> listOpp = new List<Opportunity>();
        Campaign cmp = [Select id, rC_Giving__Source_Code__c FROM Campaign where id = : c.id];
        for(Integer i=0 ; i<3 ; i++){
            Opportunity op = TestUtils.createOpportunityWithRecType(OPPORTUNITY_RT_PLEDGE_Id, acc.Id, 'Opp'+i, null, null, 'Open', c.Id, null, system.today(), false);
            op.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
            listopp.add(op);
        }
        insert listopp;
    }
}
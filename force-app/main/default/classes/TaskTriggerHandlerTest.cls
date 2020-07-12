/**
 * Test Class for TaskTriggerHandler
 **/
@isTest
private class TaskTriggerHandlerTest{
    private static testMethod void testTaskTriggerHandler(){
        Account testAcc1 = TestUtils.createAccount('testAcc1', true);
        Portfolio__c p = TestUtils.createPortfolio('testPort', true);
        String OPPORTUNITY_RT_PROPOSAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        Opportunity testOpp1 = TestUtils.createOpportunity(testAcc1.Id, 'opp1', false);
        testOpp1.RecordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        testOpp1.StageName = '01. Identify';
        testOpp1.CloseDate = system.today();
        testOpp1.rC_Giving__Requested_Amount__c = 100;
        testOpp1.Portfolio__c = p.Id;
        insert testOpp1;
        Contact testCon1 = TestUtils.createContact(testAcc1,'con1','con1',true);
        
        Confidential_Data__c cd1 = TestUtils.createConfidentialData(testAcc1.Id, testCon1.Id, testOpp1.Id, true);
        
        Task t;
        list<Task> taskList = new list<Task>();
        for(Integer i=0; i<3; i++) {
            t = TestUtils.createTask('Call', 'In Progress', false);
            t.OwnerId = UserInfo.getUserId();
            t.Priority = 'Normal';
            t.rC_Bios__Action_Plan_Task_ID__c = 'bios_action';
            t.WhatId = cd1.Id;
            taskList.add(t);
        }
        taskList[1].WhatId = testOpp1.Id;
        taskList[1].Status = 'Completed';
        taskList[2].WhatId = testOpp1.Id;
        insert taskList;
        
        //Verify AccountId and Opportunity Id populated on Task
        Task ta = [SELECT Account_Id__c,Opportunity_Id__c FROM Task WHERE ID = :taskList[0].id];
        system.assertEquals(ta.Account_Id__c, cd1.Account__c);
        system.assertEquals(ta.Opportunity_Id__c, cd1.Opportunity__c);
        
        //Verify PortfolioId populated on Task
        t = [SELECT Id, Portfolio_Id__c FROM Task WHERE Id = :taskList[2].Id];
        system.assertEquals(p.Id, t.Portfolio_Id__c);
        
        //Update
        taskList = [SELECT OwnerId,rC_Bios__Action_Plan_Task_ID__c,WhatId FROM Task];
        Task t1 = taskList.get(0);
        t1.rC_Bios__Action_Plan_Task_ID__c = 'bios';
        upsert t1;
        t1 = taskList.get(1);
        t1.WhatId = cd1.Id;
        upsert t1;
        
        taskList = [SELECT OwnerId,rC_Bios__Action_Plan_Task_ID__c,WhatId FROM Task];
        t1 = taskList.get(0);
        t1.WhatId = cd1.Id;
        t1.rC_Bios__Action_Plan_Task_ID__c = 'bios';
        upsert t1;
        t1 = taskList.get(1);
        t1.Status = 'Completed';
        t1.WhatId = testOpp1.Id;
        upsert t1;
        
        //Verify Completed Date & Stage are updated on task
        t1 = [SELECT Id, Stage__c, Completed_Date__c, Completed_by__c FROM Task WHERE Id = :t1.Id];
        system.assertEquals(t1.Completed_Date__c,system.today());
        system.assertEquals(t1.Stage__c,testOpp1.StageName);
        
        //Verify that Completed Date and Completed By are updated on task when both are null
        t1.Status = 'Pending';
        t1.Completed_date__c = NULL;
        t1.Completed_by__c = NULL;
        upsert t1;
        t1 = [SELECT Id, Stage__c, Completed_Date__c FROM Task WHERE Id = :t1.Id];
        t1.Status = 'Completed';
        upsert t1;
        t1 = [SELECT Id, Stage__c, Completed_Date__c, Completed_By__c FROM Task WHERE Id = :t1.Id];

        system.assertEquals(t1.Completed_Date__c,system.today());
        system.assertEquals(t1.Completed_by__c,UserInfo.getUserId());   
    }
}
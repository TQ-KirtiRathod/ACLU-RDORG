/*
*
*Name  :  BatchOnActionTakenTest
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test BatchOnActionTaken Class functionality
*
*/
@isTest
private class BatchOnActionTakenTest {
    private static List<sb_Actions_Taken__c> sbActionList;
    
    //This method tests the Batch when Action is taken by Web
    private static testmethod void testBatchOnActionTaken(){
        Last_Run_Time_Of_Batch__c b  = new Last_Run_Time_Of_Batch__c();
        b.Name = 'BatchOnActionTaken';
        b.Last_Run_Time__c = System.today();
        insert b;
        System.debug('>>><<'+Last_Run_Time_Of_Batch__c.getInstance('BatchOnActionTaken'));
        createData();
        insert sbActionList;
        Test.startTest();
        Database.executeBatch(new BatchOnActionTaken());
        Test.stopTest();
        System.assertEquals(1,[SELECT Id,Actions_Taken_Market_Source_by_Web__c FROM sb_action__c].Actions_Taken_Market_Source_by_Web__c);
        
    }
    
    //This method tests the Batch when Action is taken by Scanner
    private static testmethod void testBatchOnActionTaken1(){
        createData();
        insert sbActionList;
        Test.startTest();
        Database.executeBatch(new BatchOnActionTaken());
        Test.stopTest();
        System.assertEquals(1,[SELECT Id,Actions_Taken_Market_Source_by_Banner__c FROM sb_action__c].Actions_Taken_Market_Source_by_Banner__c);

    }
    
    //This method creates the required data for testing
    private static void createData(){
        sbActionList = new List<sb_Actions_Taken__c>();
        sb_action__c s = new sb_action__c();
        s.Actions_Taken_Market_Source_by_Email__c = null;
        s.Actions_Taken_Market_Source_by_Facebook__c = null;
        s.Actions_Taken_Market_Source_by_Banner__c = null;
        s.Actions_Taken_Market_Source_by_Google_Ad__c = null;
        s.Actions_Taken_Market_Source_by_Other__c = null;
        s.Actions_Taken_Market_Source_by_Twitter__c = null;
        s.Actions_Taken_Market_Source_by_Web__c = null;
        insert s;
        
        Account a = testUtils.createAccount('test', true);
        Contact c = testUtils.createContact(a, 'firstName', 'lastName', true);
        
        for(integer i = 0; i < 7; i++)
        {
            sb_Actions_Taken__c sb = new sb_Actions_Taken__c();
            sb.Initial_Market_Source_Channel__c = 'source';
            sb.Market_Source__c = 'market';
            sb.Prior_Action_Count__c = 112;
            sb.Contact__c = c.id;
            sb.Action__c = s.id;
            sb.Prior_Action_Count__c = null;
            sbActionList.add(sb);
        }
        	sbActionList[0].Initial_Market_Source_Channel__c = 'eml';
          	sbActionList[1].Initial_Market_Source_Channel__c = 'fb';
        	sbActionList[2].Initial_Market_Source_Channel__c = 'tw';
            sbActionList[3].Initial_Market_Source_Channel__c = 'web';
            sbActionList[4].Initial_Market_Source_Channel__c = 'ban';
        	sbActionList[5].Initial_Market_Source_Channel__c = 'gad';
        	sbActionList[6].Initial_Market_Source_Channel__c = 'oth';
        
    }
}
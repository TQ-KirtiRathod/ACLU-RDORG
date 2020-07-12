/*
* Developer    : Manisha Janwani
* Created      : 
* Objective    : Test Class for AccountNewHelperBatch
*/
@isTest
private class AccountNewHelperBatchTest {
    @isTest //Method to test insert case
    static void verifyLastRunCreation_UnitTest() {
        //Delete exsting Last_Run_Time_Of_Batch__c
        delete [SELECT Id FROM Last_Run_Time_Of_Batch__c];
        
        Test.startTest();
        AccountNewHelperBatch obj = new AccountNewHelperBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        
        // verify that the record is created after running the batch
        System.assertNotEquals(null, Last_Run_Time_Of_Batch__c.getInstance('AccountNewHelperBatch'));
    }
    
    @isTest //Method to test update case
    static void verifyLastRunUpdate_UnitTest() {
        Test.startTest();
        AccountNewHelperBatch obj = new AccountNewHelperBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        
        System.assertNotEquals(null,Last_Run_Time_Of_Batch__c.getValues('AccountNewHelperBatch').Last_Run_Time__c);
        System.assertEquals(Date.today(), Last_Run_Time_Of_Batch__c.getValues('AccountNewHelperBatch').Last_Run_Time__c.Date());
    }
    
    @isTest //Method to test Account AcquisitionSource Population
    static void testAccountAcquisitionSourcePopulation_UnitTest() {
        Test.startTest();
        AccountNewHelperBatch obj = new AccountNewHelperBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        
        // fetch updated accounts
        Account updatedAccount = [SELECT Id, Acquisition_Source__c FROM Account WHERE Name = 'Test0' LIMIT 1];
        Campaign camp = [SELECT rC_Giving__Source_Code__c FROM Campaign LIMIT 1];
        
        // Verify that account has popualted with campaigin giving source code
        System.assertEquals(updatedAccount.Acquisition_Source__c, camp.rC_Giving__Source_Code__c);
    }
    
    
    @isTest //test method for AccountNewHelperBatch_Schedule 
    static void testScheduleOfBatchJob() {
        //Delete exsting Last_Run_Time_Of_Batch__c
        delete [SELECT Id FROM Last_Run_Time_Of_Batch__c];
        
        Test.StartTest();
        AccountNewHelperBatch_Schedule sh1 = new AccountNewHelperBatch_Schedule();
        String sch = '0 0 0 3 9 ? '+(system.today().year() + 1);
        String jobId = system.schedule('test my AccountNewHelperBatch_Schedule', sch, sh1);
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger 
                          WHERE id = :jobId];
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals((system.today().year() + 1)+'-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest(); 
    }
    
    @testSetup //Method to create test data
    static void createtestData() {
        //creating custom settings record
        Last_Run_Time_Of_Batch__c runTimeSetting = TestUtils.createLastRunSetting('AccountNewHelperBatch', Date.today() -2, true);
        
        //Create Account and Contacts
        List<Account> accList = new List<Account>();
        List<Contact> conList = new List<Contact>();
        for(integer i = 0;i<10;i++) {
            accList.add(testUtils.createAccount('Test'+i,true));
        }
        accList[1].Acquisition_Source__c = 'test acq';
        upsert accList;
        
        for(integer i=0; i<10; i++){
            Contact con = TestUtils.createContact(accList.get(i),'testCon'+i,'testCon'+i,false);
            conList.add(con);
        }
        insert conList;
        
        //Create rC_Connect__Batch_Upload__c records
        rC_Connect__Batch_Upload__c batchUpload = testUtils.createBatchUpload('test', 'testsource', conList[0].Id, 'manisha@test.com', false);
        batchUpload.rC_Connect__Batch_Upload_Account_Matched__c = accList[1].Id;
        insert batchUpload;
        
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
        List<Opportunity> oppList1 = new List<Opportunity>();
        for(integer i=0; i<10; i++){
            Opportunity tempOpp = TestUtils.createOpportunity(accList.get(0).Id,'testOpp'+i,false);
            tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
            tempOpp.CampaignId = testCampaign1.Id;
            oppList1.add(tempOpp);
        }
        //System.debug('oppList::'+oppList1);
        if(oppList1.size()>0){
            insert oppList1;
        }
    }
}
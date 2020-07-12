/*
*Author:  Appirio India 
*Date  :  October 
*Purpose : Test Coverage for UpdateCountAndAmountOnBatchLog_Batch Class
*/
@isTest
private class UpdateCountAndAmountOnBatchLog_BatchTest {
    private static List<Batch_Log__c> batchLogLst;
    private static String OPPORTUNITY_RT_PLEDGE_Id;
    
    static {
      OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    }
    
    /* 
    *
    * Method createTestData
    * Creating Test Data
    */
    private static void createTestData() {
      batchLogLst = new List<Batch_Log__c>();
      List<Opportunity> opptyLst = new List<Opportunity>();
      Batch_Log__c testBatchLog;
      Opportunity testOppty;
      
      Batch_Upload_Source_File__c setting = TestUtils.createBatchUploadSourceFileSetting('Springboard', 'S', true);
      
      // Account Record
      Account testAcc1 = TestUtils.createAccount('testAcc1', true);
      
      // Batch Log Records
      for(Integer i=0; i <10; i++) {
        testBatchLog = TestUtils.batchLog('testBatchLog'+i, false);
          testBatchLog.Batch_Date__c = System.today();
          testBatchLog.Batch_Log_Type__c = 'Springboard';
          testBatchLog.Batch_Log_Status__c = 'Open';
          batchLogLst.add(testBatchLog);
      }
      
      if(!batchLogLst.isEmpty()) {
        insert batchLogLst;
      }
      Id OPP_RT_DONATION_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
      // Opportunity Records
      for(Integer j=0; j <10; j++) {
        testOppty = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
          testOppty.RecordTypeId = OPP_RT_DONATION_ID;
          testOppty.Batch_Log__c = batchLogLst[j].Id;
          testOppty.Batch_Log_Update_Date__c = System.today().addDays(1);
          testOppty.Amount = 100;
          opptyLst.add(testOppty);
      }
      
      if(!opptyLst.isEmpty()) {
        insert opptyLst;
      }
    }
    
    /* 
    *
    * Method testBatchWithArgumentsInConstructor
    * Testing Batch fuctinality for bulk records
    */
    private static testMethod void testBatchWithArgumentsInConstructor(){
        
        createTestData();
        UpdateCountAndAmountOnBatchLog_Batch obj = new UpdateCountAndAmountOnBatchLog_Batch(batchLogLst[0].Id);
        Test.startTest();

            DataBase.executeBatch(obj); 
            
        Test.stopTest();
        
        for(Batch_Log__c objLog : [SELECT Id, Actual_Count__c, Actual_Amount__c FROM Batch_Log__c WHERE Id =: batchLogLst[0].Id]) {
          system.assertEquals(1, objLog.Actual_Count__c);
          system.assertEquals(20, objLog.Actual_Amount__c);
        }
    }
    
     /* 
    *
    * Method testBatchWithIDSetArgInConstructor
    * Testing Batch fuctionality for bulk records
    */
    private static testMethod void testBatchWithIDSetArgInConstructor(){
        
        createTestData();
        Set<Id> testIds = new Set<Id>();
        for (Batch_Log__c bl : batchLogLst) {
        	testIds.add(bl.Id);
        }
        UpdateCountAndAmountOnBatchLog_Batch obj = new UpdateCountAndAmountOnBatchLog_Batch(testIds);
        Test.startTest();

            DataBase.executeBatch(obj); 
            
        Test.stopTest();
        
        for(Batch_Log__c objLog : [SELECT Id, Actual_Count__c, Actual_Amount__c FROM Batch_Log__c WHERE Id =: batchLogLst[0].Id]) {
          system.assertEquals(1, objLog.Actual_Count__c);
          system.assertEquals(20, objLog.Actual_Amount__c);
        }
    }
    
     
    /* 
    *
    * Method testBatchWithDateRangeInConstructor
    * Testing Batch fuctionality for bulk records
    */
    private static testMethod void testBatchWithDateRangeInConstructor(){
        
        createTestData();
        UpdateCountAndAmountOnBatchLog_Batch obj = new UpdateCountAndAmountOnBatchLog_Batch(System.today(), System.today());
        Test.startTest();

            DataBase.executeBatch(obj); 
            
        Test.stopTest();
        
        for(Batch_Log__c objLog : [SELECT Id, Actual_Count__c, Actual_Amount__c FROM Batch_Log__c WHERE Id =: batchLogLst[0].Id]) {
          system.assertEquals(1, objLog.Actual_Count__c);
          system.assertEquals(20, objLog.Actual_Amount__c);
        }
    }
    
    /* 
    *
    * Method testBatchWithNoArgumentsInConstructor
    * Testing Batch fuctinality for bulk records
    */
    private static testMethod void testBatchWithNoArgumentsInConstructor(){
        
        createTestData();
        UpdateCountAndAmountOnBatchLog_Batch obj = new UpdateCountAndAmountOnBatchLog_Batch();
        Test.startTest();

            DataBase.executeBatch(obj); 
            
        Test.stopTest();
        
        for(Batch_Log__c objLog : [SELECT Id, Actual_Count__c, Actual_Amount__c FROM Batch_Log__c]) {
          system.assertEquals(1, objLog.Actual_Count__c);
          system.assertEquals(20, objLog.Actual_Amount__c);
        }
    }
    
    /* 
    *
    * Method testUpdateCountAndAmountOnBatchLog_Schedule
    * Testing Scheduler Class
    */
    private static testMethod void testUpdateCountAndAmountOnBatchLog_Schedule(){
        Test.startTest();
            Datetime dt = Datetime.now().addMinutes(1);
            String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
            String jobId = System.schedule('UpdateCountAndAmountOnBatchLog_Schedule'+System.now(), CRON_EXP, new UpdateCountAndAmountOnBatchLog_Schedule() );   
        Test.stopTest();
        system.assert(jobId != null);
    }
}
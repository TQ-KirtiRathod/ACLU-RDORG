@isTest
public class BatchLogManagerTest {
    private static Id[] batchLogIdArray;
    private static Batch_Log__c batchLog;
    private static List<Batch_Log__c> batchLogList;
    private static Opportunity mainOpp;
    private static Account acc;
    private static List<Opportunity> oppList;

    @isTest
    static void testUpdateBatchLogStatus(){
        createBatchTestData(2);
        BatchLogManager.updateBatchLogStatus(batchLogIdArray[0]);
        system.assertEquals('Balanced',[SELECT Batch_Log_Status__c FROM Batch_Log__c WHERE Id=:batchLogIdArray[0]][0].Batch_Log_Status__c);   
        BatchLogManager.updateBulkBatchLogStatus(batchLogIdArray);
        for(Batch_Log__c blg: [SELECT Batch_Log_Status__c FROM Batch_Log__c]){
            system.assertEquals('Balanced',blg.Batch_Log_Status__c);
        }
    }
    @isTest
    static void testAssociateAdjustmentLog(){
        //Create Batch Records
        createBatchTestData(2);
        // fetching the created records to use Id 
        List<Batch_Log__c> fetchedBatchLogList = [SELECT id, name FROM Batch_Log__c];
        //List<Opportunity> oppList= new List<Opportunity>();
         
        //Opportunity mainOpp = TestUtils.createOpportunity(acc.Id , 'testOpportunity' , false);
        /*mainOpp.Batch_Log__c = fetchedBatchLogList.get(0).Id;
        mainOpp.Batch_Date__c = Date.today()-1;
        mainOpp.Amount = 100;
        insert mainOpp;*/
        /*for (Integer i = 0 ; i < 2 ; i++){
            Opportunity opp = TestUtils.createOpportunity(acc.Id , 'testOpportunity' + i , false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
            opp.Adjustment_Code__c = 'B';
            opp.Adjustment_Batch__c = fetchedBatchLogList.get(i).Id;
            opp.Related_Transaction__c = mainOpp.Id;
            opp.Batch_Log__c = fetchedBatchLogList.get(i).Id;
            opp.Batch_Date__c = Date.today()-1;
            opp.Amount = 100;
            oppList.add(opp);
        }
        if(oppList.size()>0){
            insert oppList;
        }*/
        mainOpp = [SELECT id,name,RecordTypeId,Adjustment_Code__c,Adjustment_Batch__c,Related_Transaction__c,
                  Batch_Log__c,Batch_Date__c,Amount,rC_Giving__Parent__c
                  FROM Opportunity 
                  WHERE Name='testOpportunity'][0];
        mainOpp.rC_Giving__Parent__c = oppList.get(0).Id;
        upsert mainOpp;
        
        BatchLogManager.AdjustmentLogResult adjLogResult = BatchLogManager.associateAdjustmentLog(mainOpp.Id , null);
        BatchLogManager.AdjustmentLogResult empW = new BatchLogManager.AdjustmentLogResult(); 
        
        //verifying the opportunity record adjustmentBatch not null
        system.assertNotEquals(null, [SELECT Id, Adjustment_Batch__c FROM Opportunity WHERE id=: mainOpp.Id]);
        system.assertNotEquals(null,adjLogResult.batchId);
        system.assertEquals('CNUM1706220003',[ SELECT id,Name FROM Batch_Log__c where Id=:adjLogResult.batchId][0].name);
    }
    
    @isTest
    static void testAssociateAdjustmentLog2(){
        createBatchTestData(2);
        List<Batch_Log__c> fetchedBatchLogList1 = [SELECT id, name,Batch_Type__c FROM Batch_Log__c];
        List<Batch_Log__c> updateBatchLogList1 = new List<Batch_Log__c>();
        for(Batch_Log__c bl:fetchedBatchLogList1){
            bl.Batch_Type__c = 'Adjustment';
            updateBatchLogList1.add(bl);
        }
        upsert updateBatchLogList1;
        
        //List<Opportunity> oppList= new List<Opportunity>();
        //Account acc = TestUtils.createAccount('testAccount', true);
        
        /*mainOpp.Batch_Log__c = fetchedBatchLogList1.get(0).Id;
        mainOpp.Batch_Date__c = Date.today()-1;
        mainOpp.Amount = 100;
        insert mainOpp;*/
        
        mainOpp = [SELECT id,name,RecordTypeId,Adjustment_Code__c,Adjustment_Batch__c,Related_Transaction__c,
                  Batch_Log__c,Batch_Date__c,Amount,rC_Giving__Parent__c
                  FROM Opportunity 
                  WHERE Name='testOpportunity'][0];
        
        BatchLogManager.AdjustmentLogResult adjLogResult = BatchLogManager.associateAdjustmentLog(mainOpp.Id , null);
        //verifying the batchId
        system.assertNotEquals(null,adjLogResult.batchId);
        //system.assertEquals('CNUM1706220001FM1710130001',[ SELECT id,Name FROM Batch_Log__c where Id=:adjLogResult.batchId][0].name);
    }
    
    //Added below method to test createAdjustmentRecords() - 11/20/2017 - KM
    @isTest
    static void testCreateAdjustmentRecords(){
        createBatchTestData(2);
        List<Batch_Log__c> fetchedBatchLogList1 = [SELECT id, name,Batch_Type__c FROM Batch_Log__c];
        List<Batch_Log__c> updateBatchLogList1 = new List<Batch_Log__c>();
        
        
        
        mainOpp = [SELECT id,name,RecordTypeId,Adjustment_Code__c,Adjustment_Batch__c,Related_Transaction__c,
                  Batch_Log__c,Batch_Date__c,Amount,rC_Giving__Parent__c
                  FROM Opportunity 
                  WHERE Name='testOpportunity'][0];
        
        List<Opportunity> oppList = BatchLogManager.createAdjustmentRecords(fetchedBatchLogList1[0], mainOpp);
        
        System.assertEquals(oppList.size(),3);
        System.assertEquals(oppList[0].Adjustment__c, true);
        System.assertEquals(oppList[1].StageName, mainOpp.StageName);
        System.assertEquals(oppList[1].rC_Giving__Transaction_Type__c, 'Adjustment');
        System.assertEquals(oppList[2].Adjustment_Code__c, 'D');
        System.assertEquals(oppList[2].Adjustment_Sequence__c, 1);
    }
    
    @isTest
    static void testResetMembership(){
        createBatchTestData(2);
        Opportunity opp = [Select Id,AccountId, account.Original_Join_Date__c, Account.Last_Membership_Gift__c,Account.Last_Membership_Gift__r.CloseDate FROM Opportunity LIMIT 1];
        Account acc = [Select Id FROM Account LIMIT 1];
        Opportunity op = TestUtils.createOpportunity(acc.Id , 'testOpportunity' , false);
        op.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        op.Adjustment_Code__c = 'B';
        op.closeDate = Date.today();
        insert op;
        acc.Last_Membership_Gift__c = op.id;
        acc.Original_Join_Date__c = Date.today();
        update acc;
        opp = [Select Id,AccountId, account.Original_Join_Date__c, Account.Last_Membership_Gift__r.CloseDate FROM Opportunity where id =: opp.id LIMIT 1];
        new BatchLogManager().BatchResetMembershipMethod(opp, true);
        
        opp = [Select Id, AccountId, Sharing_Code__c , rC_Giving__External_ID__c FROM Opportunity WHERE id = :opp.Id];
        System.assertEquals(null, opp.Sharing_Code__c );
        System.assertEquals(null, opp.rC_Giving__External_ID__c );
        
        acc = [Select Id,Last_Membership_Gift__c,Membership_Expiration_date__c, Original_Join_Date__c From Account where Id = : opp.AccountId ];
        System.assertEquals(null , acc.Last_Membership_Gift__c );
        System.assertEquals(null, acc.Membership_Expiration_date__c );
        System.assertEquals(null, acc.Original_Join_Date__c );
    }
    
    //test case when there is no last membership gift in account
    @isTest
    static void testResetMembershipTest2(){
        createBatchTestData(2);
        Opportunity opp = [Select Id,AccountId, account.Original_Join_Date__c, Account.Last_Membership_Gift__c, Account.Last_Membership_Gift__r.CloseDate FROM Opportunity LIMIT 1];
        Account acc = [Select Id FROM Account LIMIT 1];
        acc.Original_Join_Date__c = Date.today();
        update acc;
        opp = [Select Id,AccountId, account.Original_Join_Date__c,Account.Last_Membership_Gift__c, Account.Last_Membership_Gift__r.CloseDate FROM Opportunity where id =: opp.id LIMIT 1];
        new BatchLogManager().BatchResetMembershipMethod(opp, true);
        
        opp = [Select Id, AccountId, Sharing_Code__c , rC_Giving__External_ID__c FROM Opportunity WHERE id = :opp.Id];
        System.assertEquals(null, opp.Sharing_Code__c );
        System.assertEquals(null, opp.rC_Giving__External_ID__c );
        
        acc = [Select Id,Last_Membership_Gift__c,Membership_Expiration_date__c, Original_Join_Date__c From Account where Id = : opp.AccountId ];
        System.assertEquals(null , acc.Last_Membership_Gift__c );
        System.assertEquals(null, acc.Membership_Expiration_date__c );
        System.assertEquals(Date.today(), acc.Original_Join_Date__c );
    }
    
    //test case when there is  last membership gift close date and join date in account,doest not match
    @isTest
    static void testResetMembershipTest3(){
        createBatchTestData(2);
        Opportunity opp = [Select Id,AccountId, account.Original_Join_Date__c, Account.Last_Membership_Gift__c, Account.Last_Membership_Gift__r.CloseDate FROM Opportunity LIMIT 1];
        Account acc = [Select Id FROM Account LIMIT 1];
        Opportunity op = TestUtils.createOpportunity(acc.Id , 'testOpportunity' , false);
        op.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        op.Adjustment_Code__c = 'B';
        op.closeDate = Date.today().addDays(1);
        insert op;
        acc.Last_Membership_Gift__c = op.id;
        acc.Original_Join_Date__c = Date.today();
        update acc;
        opp = [Select Id,AccountId, account.Original_Join_Date__c, Account.Last_Membership_Gift__c,  Account.Last_Membership_Gift__r.CloseDate FROM Opportunity where id =: opp.id LIMIT 1];
        new BatchLogManager().BatchResetMembershipMethod(opp, true);
        
        opp = [Select Id, AccountId, Sharing_Code__c , rC_Giving__External_ID__c FROM Opportunity WHERE id = :opp.Id];
        System.assertEquals(null, opp.Sharing_Code__c );
        System.assertEquals(null, opp.rC_Giving__External_ID__c );
        
        acc = [Select Id,Last_Membership_Gift__c,Membership_Expiration_date__c, Original_Join_Date__c From Account where Id = : opp.AccountId ];
        System.assertEquals(null , acc.Last_Membership_Gift__c );
        System.assertEquals(null, acc.Membership_Expiration_date__c );
        System.assertEquals(Date.today(), acc.Original_Join_Date__c );
    }
    
    //Create TestData
    static void createBatchTestData(Integer batchLogCount){
        batchLogList = new List<Batch_Log__c>();
        oppList= new List<Opportunity>();
        batchLogIdArray = new Id[batchLogCount];
               
        //Create BatchLog
        for(Integer i = 0; i<batchLogCount; i++){
            Batch_Log__c batchLog = TestUtils.createBatchLog( 'batchTestName' + i, false);
            batchLog.Name = 'CNUM1706220001';
            batchLog.Actual_Amount__c = 100;
            batchLog.Expected_Amount__c = 100;
            batchLog.Actual_Count__c = 1;
            batchLog.Expected_Count__c = 1;
            batchLog.Batch_Date__c = Date.today()-1;
            batchLogList.add(batchLog);
        }
        insert batchLogList;
        for(integer i=0; i<batchLogCount; i++){
            batchLogIdArray[i] = batchLogList.get(i).Id;
        }
        
        //Create Account 
        acc = TestUtils.createAccount('testAccount', true);
        //Create Opportunity
        mainOpp = TestUtils.createOpportunity(acc.Id , 'testOpportunity' , false);
        mainOpp.Batch_Log__c = batchLogList.get(0).Id;
        mainOpp.Batch_Date__c = Date.today()-1;
        mainOpp.Amount = 100;
        mainOpp.StageName = 'Open';
        insert mainOpp;
        
        // Create Transaction records
        for (Integer i = 0 ; i < 2 ; i++){
            Opportunity opp = TestUtils.createOpportunity(acc.Id , 'testOpportunity' + i , false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
            opp.Adjustment_Code__c = 'B';
            opp.Adjustment_Batch__c = batchLogList.get(i).Id;
            opp.Related_Transaction__c = mainOpp.Id;
            opp.Batch_Log__c = batchLogList.get(i).Id;
            opp.Batch_Date__c = Date.today()-1;
            opp.Amount = 100;
            oppList.add(opp);
        }
        if(oppList.size()>0){
            insert oppList;
        }
    }
}
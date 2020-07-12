/**
 * Test Class for BatchCalculateExpectedCountAmount
 **/
 @isTest
private class BatchCalculateExpectedCountAmount_Test {
    private static list<Batch_Log__c> logList;
    private static void TestMatchBatchLogViaBatchUpload(){
        Test.StartTest();   
            createTestData();  
            set<Id> batchLogIds = new set<Id>();
            for(Batch_Log__c b : logList) {
                batchLogIds.add(b.Id);
            }
            Database.executebatch(new BatchCalculateExpectedCountAmount(batchLogIds), 50);
            List<Batch_Log__c> lstBL = [SELECT Id, Expected_Count__c, Expected_Amount__c 
                                        FROM Batch_Log__c
                                        WHERE Id IN :batchLogIds];
            system.assert(lstBL.size() == 3);
            system.assert(lstBL[0].Expected_Count__c == 10);
            system.assert(lstBL[1].Expected_Count__c == 10);
            system.assert(lstBL[2].Expected_Count__c == 10);
            system.assert(lstBL[0].Expected_Amount__c == 100);
            system.assert(lstBL[1].Expected_Amount__c == 200);
            system.assert(lstBL[2].Expected_Amount__c == 300);
        Test.stopTest();   
    }
    
    private static void createTestData() {
        // Batch Log Test Data
        Id VENDOR_RCD_TYPE_ID = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        logList = new list<Batch_Log__c>();
        for(Integer i =0; i < 3; i++) {
            Batch_Log__c objLog = TestUtils.createBatchLog('test',false);
            objLog.Batch_Log_Status__c = 'Open';
            objLog.Deposit_Site__c = 'NAV_NatU_Operating_cc';
            objLog.Batch_Date__c = system.today();
            objLog.Batch_Type__c = 'Standard';
            objLog.RecordTypeId = VENDOR_RCD_TYPE_ID;
            logList.add(objLog);
        }
        insert logList;
        
        // Batch Upload Test Data
        list<rC_Connect__Batch_Upload__c> listConnectBatchUpload = new List<rC_Connect__Batch_Upload__c>();
        for(Integer i=0;i<30;i++){
            rC_Connect__Batch_Upload__c obj = TestUtils.createBatchUpload('Test'+i,'Test', null, 'test@gmail.com', False);
            obj.Batch_Upload_Deposit_Site__c='AA - Undefined';
            obj.rC_Connect__Batch_Upload_Source_File__c='Springboard';
            obj.rC_Connect__Giving_Record_Type__c='Pledge';
            obj.rC_Connect__Batch_Upload_Status__c='Flagged';
            obj.rC_Connect__Giving_Close_Date__c = system.today();
            obj.isSoft_Credit__c = false;
            if(i >= 0 && i <=10) {
                obj.rC_Connect__Giving_Giving_Amount__c=10;
                obj.Batch_Log__c = logList[0].Id;
            }
            if(i >= 10 && i <=20) {
                obj.rC_Connect__Giving_Giving_Amount__c=20;
                obj.Batch_Log__c = logList[1].Id;
            }
            if(i >= 20 && i <=30) {
                obj.rC_Connect__Giving_Giving_Amount__c=30;
                obj.Batch_Log__c = logList[2].Id;
            }
            listConnectBatchUpload.add(obj);
        }
        insert listConnectBatchUpload;
    }
}
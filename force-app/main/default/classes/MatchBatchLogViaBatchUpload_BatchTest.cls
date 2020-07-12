/**
 * Test Class for MatchBatchLogViaBatchUpload_Batch
 **/
@isTest
private class MatchBatchLogViaBatchUpload_BatchTest {
    private static List<rC_Connect__Batch_Upload__c> listConnectBatchUpload;
    private Static List<Batch_Log__c> listBatchLog;
    private static Id VENDOR_RCD_TYPE_ID = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    private static Id OPPORTUNITY_RT_DONATION_Id = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    private static Id OPPORTUNITY_RT_TRANSACTION_Id = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    
    @isTest
    private static void TestMatchBatchLogViaBatchUpload(){
        Test.StartTest();   
            createData();  
            Database.executebatch(new MatchBatchLogViaBatchUpload_Batch(), 200);
            List<Batch_Log__c> lstBL = [Select Id from Batch_Log__c Limit 10];
            system.assert(lstBL.size() > 0);
        Test.stopTest();   
    }
    
    @isTest
    private static void TestMatchBatchLogViaBatchUpload1(){
        Test.StartTest();   
            createData();  
            Database.executebatch(new MatchBatchLogViaBatchUpload_Batch(listConnectBatchUpload.get(0).id), 200); 
        Test.stopTest(); 
        rC_Connect__Batch_Upload__c updatedBatchUpload = [SELECT Id, Batch_Log__c, rC_Connect__Batch_Upload_Giving_Matched__c,
                                                                rC_Connect__Batch_Upload_Giving_Matched__r.Batch_Log__c,
                                                                rC_Connect__Batch_Upload_Giving_Matched__r.Batch_Date__c,
                                                                rC_Connect__Batch_Upload_Giving_Matched__r.Batch_Log__r.Batch_Date__c
                                                            FROM rC_Connect__Batch_Upload__c 
                                                            WHERE Id =: listConnectBatchUpload.get(0).id];
        system.assertEquals(true, updatedBatchUpload.Batch_Log__c != null);
        system.assertEquals(updatedBatchUpload.rC_Connect__Batch_Upload_Giving_Matched__r.Batch_Log__r.Batch_Date__c, updatedBatchUpload.rC_Connect__Batch_Upload_Giving_Matched__r.Batch_Date__c);   
    }
    
    @isTest
    private static void TestMatchBatchLogViaBatchUpload2(){
        Test.StartTest();   
            createData();   
            Database.executebatch(new MatchBatchLogViaBatchUpload_Batch(listConnectBatchUpload.get(1).id), 200);
        Test.stopTest();  
        rC_Connect__Batch_Upload__c updatedBatchUpload = [SELECT Id, Batch_Log__c FROM rC_Connect__Batch_Upload__c WHERE Id =: listConnectBatchUpload.get(1).id];
        system.assertEquals(true, updatedBatchUpload.Batch_Log__c != null);
    }
    
    //Create test data
    public static void createData(){
        listConnectBatchUpload = new List<rC_Connect__Batch_Upload__c>();
        
        Account acc = TestUtils.createAccount('Test',True);        
        Contact con = TestUtils.createContact(acc, 'firstName', 'Test', True);
        Campaign cmpgn = TestUtils.createCampaign('TestCampaign', false);
        cmpgn.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert cmpgn;
        Opportunity oppty = TestUtils.createOpportunityWithRecType(OPPORTUNITY_RT_DONATION_Id, acc.Id, 'ParentOpp', null, null, 'Open', cmpgn.Id, 1000, system.today(), true);
        Opportunity opptyChild = TestUtils.createOpportunityWithRecType(OPPORTUNITY_RT_TRANSACTION_Id, acc.Id, 'ChildOpp', null, null, 'Completed', cmpgn.Id, 1000, system.today(), false);
        opptyChild.rC_Giving__Parent__c = oppty.Id;
        insert opptyChild;
        
        // Batch Upload Test Data
        for(Integer i=0;i<10;i++){
            rC_Connect__Batch_Upload__c obj = TestUtils.createBatchUpload('Test'+i,'Test', con.id, 'test@gmail.com', False);
            obj.Batch_Upload_Deposit_Site__c='AK_Alaska';
            obj.rC_Connect__Giving_Giving_Amount__c=10+i;
            obj.rC_Connect__Batch_Upload_Source_File__c='Springboard';
            obj.rC_Connect__Giving_Record_Type__c='Pledge';
            obj.rC_Connect__Batch_Upload_Status__c='Flagged';
            obj.rC_Connect__Giving_Close_Date__c = system.today();
            obj.rC_Connect__Batch_Upload_Giving_Matched__c = oppty.Id;
            obj.isSoft_Credit__c = false;
            obj.rC_Connect__Batch_Upload_Campaign_Matched__c = cmpgn.id;
            listConnectBatchUpload.add(obj);
        }
        listConnectBatchUpload.get(0).Batch_Upload_Deposit_Site__c = 'NAV_NatU_Operating_cc';
        insert listConnectBatchUpload;
        
        // Custom Setting Test Data
        Batch_Upload_Source_File__c uploadSetting = TestUtils.createBatchUploadSourceFileSetting('Springboard', 'S', false);
        insert uploadSetting;
        
        // Batch Log Test Data
        Batch_Log__c objLog = TestUtils.createBatchLog('test',false);
        objLog.Batch_Log_Status__c = 'Open';
        objLog.Deposit_Site__c = 'NAV_NatU_Operating_cc';
        objLog.Batch_Date__c = system.today();
        objLog.Batch_Type__c = 'Standard';
        objLog.RecordTypeId = VENDOR_RCD_TYPE_ID;
        insert objLog;
    }
}
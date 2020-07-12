/**
 * Test Class for BatchLogOppBalancingBatchTest
 **/
@isTest
public class BatchLogOppBalancingBatchTest {
    private static List<rC_Connect__Batch_Upload__c> listConnectBatchUpload;
    private Static List<Batch_Log__c> listBatchLog;
    private static Id VENDOR_RCD_TYPE_ID = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    private static Id OPPORTUNITY_RT_DONATION_Id = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    private static Id OPPORTUNITY_RT_TRANSACTION_Id = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    
    @isTest
    private static void TestBatchLogOppBalancingBatch(){
        Test.StartTest();   
        createData();  
       
        List<Batch_Log__c> lstBL = [Select Id from Batch_Log__c Limit 10];
        List<id> batchLogIds = new List<Id>();
        for( Batch_Log__c batchLog :lstBL) {
            batchLogIds.add(batchLog.id);
        }
        Database.executebatch(new BatchLogOppBalancingBatch(batchLogIds), 200);
        system.assert(lstBL.size() > 0);
        
        Test.stopTest(); 
        List<Opportunity> opportunityList = [SELECT id,Batch_Log__c,Batch_Date__c FROM Opportunity];
        System.assert(opportunityList[0].Batch_Log__c != null , true);
    }
    @isTest
    private static void TestBatchLogOppBalancingBatchDateRange(){
        Test.StartTest();   
        createData();  
        Database.executebatch(new BatchLogOppBalancingBatch(System.Today().addDays(-1),System.Today().addDays(1)), 200);
        
        Test.stopTest(); 
        List<Opportunity> opportunityList = [SELECT id,Batch_Log__c,Batch_Date__c FROM Opportunity];
        System.assert(opportunityList[0].Batch_Log__c != null , true);
    }
    
    @isTest
    private static void TestBatchLogOppBalancingBatchQueryBulk(){
        Test.StartTest();   
        createBulkData();  
        String query = 'SELECT Id, rC_Connect__Giving_Giving_Amount__c, Batch_Log__r.Batch_Date__c,rC_Connect__Batch_Upload_Giving_Matched__c,rC_Connect__Batch_Upload_Giving_Matched__r.recordtypeid,rC_Connect__Batch_Upload_Giving_Matched__r.recordtype.name,Batch_Log__c, Batch_Log__r.Expected_Amount__c, Batch_Log__r.Expected_Count__c FROM rC_Connect__Batch_Upload__c';
        Database.executebatch(new BatchLogOppBalancingBatch(query),200);
        
        Test.stopTest(); 
        List<Opportunity> opportunityList = [SELECT id,Batch_Log__c,Batch_Date__c FROM Opportunity];
        System.assert(opportunityList[0].Batch_Log__c != null , true);
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
       
        
        // Custom Setting Test Data
        Batch_Upload_Source_File__c uploadSetting = TestUtils.createBatchUploadSourceFileSetting('Springboard', 'S', false);
        insert uploadSetting;
        
        // Batch Log Test Data
        List<Batch_Log__c> batchLogList = new List<Batch_Log__c>();
        for(Integer i=0;i<1;i++){
            Batch_Log__c objLog = TestUtils.createBatchLog('test',false);
            objLog.Batch_Log_Status__c = 'Open';
            objLog.Deposit_Site__c = 'NAV_NatU_Operating_cc';
            objLog.Batch_Date__c = system.today();
            objLog.Batch_Type__c = 'Standard';
            objLog.RecordTypeId = VENDOR_RCD_TYPE_ID;
            batchLogList.add(objLog);
        }
        insert batchLogList;
         for(Integer i=0;i<1;i++){
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
            obj.Batch_Log__c = batchLogList[i].id;
            listConnectBatchUpload.add(obj);
        }
        listConnectBatchUpload.get(0).Batch_Upload_Deposit_Site__c = 'NAV_NatU_Operating_cc';
        insert listConnectBatchUpload;
    }
    //Create test data
    public static void createBulkData(){
        listConnectBatchUpload = new List<rC_Connect__Batch_Upload__c>();
        
        Account acc = TestUtils.createAccount('Test',True);        
        Contact con = TestUtils.createContact(acc, 'firstName', 'Test', True);
        Campaign cmpgn = TestUtils.createCampaign('TestCampaign', false);
        cmpgn.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert cmpgn;
        List<Opportunity> opList = new List<Opportunity>();
        for(Integer i=0;i<2;i++){
            Opportunity oppty = TestUtils.createOpportunityWithRecType(OPPORTUNITY_RT_DONATION_Id, acc.Id, 'ParentOpp', null, null, 'Open', cmpgn.Id, 1000, system.today(), true);
            opList.add(oppty);
        }
        update opList;
       
        
        // Custom Setting Test Data
        Batch_Upload_Source_File__c uploadSetting = TestUtils.createBatchUploadSourceFileSetting('Springboard', 'S', false);
        insert uploadSetting;
        
        // Batch Log Test Data
        List<Batch_Log__c> batchLogList = new List<Batch_Log__c>();
        for(Integer i=0;i<2;i++){
            Batch_Log__c objLog = TestUtils.createBatchLog('test',false);
            objLog.Batch_Log_Status__c = 'Open';
            objLog.Deposit_Site__c = 'NAV_NatU_Operating_cc';
            objLog.Batch_Date__c = system.today();
            objLog.Batch_Type__c = 'Standard';
            objLog.RecordTypeId = VENDOR_RCD_TYPE_ID;
            batchLogList.add(objLog);
        }
        insert batchLogList;
        opList[0].Batch_Log__c = batchLogList[0].id;
        update opList[0];
        
         for(Integer i=0;i<2;i++){
            rC_Connect__Batch_Upload__c obj = TestUtils.createBatchUpload('Test'+i,'Test', con.id, 'test@gmail.com', False);
            obj.Batch_Upload_Deposit_Site__c='AK_Alaska';
            obj.rC_Connect__Giving_Giving_Amount__c=10+i;
            obj.rC_Connect__Batch_Upload_Source_File__c='Springboard';
            obj.rC_Connect__Giving_Record_Type__c='Pledge';
            obj.rC_Connect__Batch_Upload_Status__c='Flagged';
            obj.rC_Connect__Giving_Close_Date__c = system.today();
            obj.rC_Connect__Batch_Upload_Giving_Matched__c = opList[i].Id;
            obj.isSoft_Credit__c = false;
            obj.rC_Connect__Batch_Upload_Campaign_Matched__c = cmpgn.id;
            obj.Batch_Log__c = batchLogList[i].id;
            listConnectBatchUpload.add(obj);
        }
        for(Integer i=0;i<1;i++){
            rC_Connect__Batch_Upload__c obj = TestUtils.createBatchUpload('Test'+i,'Test', con.id, 'test@gmail.com', False);
            obj.Batch_Upload_Deposit_Site__c='AK_Alaska';
            obj.rC_Connect__Giving_Giving_Amount__c=10+i;
            obj.rC_Connect__Batch_Upload_Source_File__c='Springboard';
            obj.rC_Connect__Giving_Record_Type__c='Pledge';
            obj.rC_Connect__Batch_Upload_Status__c='Flagged';
            obj.rC_Connect__Giving_Close_Date__c = system.today();
            obj.rC_Connect__Batch_Upload_Giving_Matched__c = opList[i].Id;
            obj.isSoft_Credit__c = false;
            obj.rC_Connect__Batch_Upload_Campaign_Matched__c = cmpgn.id;
            obj.Batch_Log__c = batchLogList[i].id;
            listConnectBatchUpload.add(obj);
        }
        listConnectBatchUpload.get(0).Batch_Upload_Deposit_Site__c = 'NAV_NatU_Operating_cc';
        insert listConnectBatchUpload;
    }

}
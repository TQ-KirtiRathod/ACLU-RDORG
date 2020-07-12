/**
 * Test Class for Monthly_Cash_Receipt_File_Controller
 **/
@isTest
public class Monthly_Cash_Receipt_File_ControllerTest {

    @isTest
    public static void testMonthly_Cash_Receipt_File_Controller1()
    {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.Monthly_Cash_Receipt_File;
        //In this case, the Visualforce page named 'Monthly_Cash_Receipt_File' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        Batch_log__c batchLog = TestUtils.createBatchLog('Test', false);
        batchLog.Batch_Date__c = system.today();
        batchLog.Bank_Date__c = system.today() - 100;
        insert batchLog;
        
        Monthly_Cash_Receipt_File_Controller m = new Monthly_Cash_Receipt_File_Controller();
        m.batchLog = batchLog;
        m.selectedReportType = 'batch_Credit_Card_summary';
        
        Monthly_Cash_Receipts_Controls__c mc = TestUtils.createCashReceiptsControls('new test', null, null, null, null, null, false);
        
        Test.startTest();
        insert mc;
        m.validation();
        m.save();
        Test.stopTest();
        mc = [SELECT Id, Report_Request_Owner_Email__c FROM Monthly_Cash_Receipts_Controls__c WHERE Id = :mc.Id];
        System.assertEquals(mc.Report_Request_Owner_Email__c,UserInfo.getUserEmail());
            System.assertNotEquals(null,batchLog.Bank_Date__c);
            System.assertNotEquals(null,batchLog.Batch_Date__c);
    }
    
    
    //batchlog values null
    @isTest
    public static void testMonthly_Cash_Receipt_File_Controller2()
    {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.Monthly_Cash_Receipt_File;
        //In this case, the Visualforce page named 'Monthly_Cash_Receipt_File' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        Batch_log__c batchLog = TestUtils.createBatchLog('Test', false);
        Monthly_Cash_Receipt_File_Controller m = new Monthly_Cash_Receipt_File_Controller();
        m.batchLog = batchLog;
        Test.startTest();
        m.save();
        m.validation();
        Test.stopTest();
        
        System.assertEquals(null,batchLog.Bank_Date__c);
    }
    
    
       //for selectedReportType not matching
       @isTest
        public static void testMonthly_Cash_Receipt_File_Controller3()
        {
            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.Monthly_Cash_Receipt_File;
            //In this case, the Visualforce page named 'Monthly_Cash_Receipt_File' is the starting point of this test method.
            Test.setCurrentPage(pageRef);
            
            Batch_log__c batchLog = new Batch_log__c();
            batchLog.Batch_Date__c = system.today();
            batchLog.Bank_Date__c = system.today() - 100;
            insert batchLog;
            
            Monthly_Cash_Receipt_File_Controller m = new Monthly_Cash_Receipt_File_Controller();
            m.batchLog = batchLog;
            m.selectedReportType = null;
            
            Monthly_Cash_Receipts_Controls__c mc = TestUtils.createCashReceiptsControls('new test', null, null, null, null, null, false);
        
            Test.startTest();
            insert mc;
            m.validation();
            m.save();
            Test.stopTest();
        
            System.assertNotEquals(null,batchLog.Bank_Date__c);
            System.assertNotEquals(null,batchLog.Batch_Date__c);
        }
        
}
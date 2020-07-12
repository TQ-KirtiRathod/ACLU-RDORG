@isTest
private class Cash_Receipt_ReportsControllerTest {
    public  static Date date1 = Date.newInstance(2018, 01,01);//Date.today();
    public  static Date date2 = Date.newInstance(2018, 01,02);//Date.today().adddays(1);
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerErrorsTest(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];   
                                                 
        Test.startTest();
        
        System.runAs(usr) {
            listOpportunity.get(0).Sharing_Code__c = 'K161';
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','Errors');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() == 0);
        Test.stopTest();
    }
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerBatchCreditCardSummaryTest(){
        Test.startTest();
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','batch_Credit_Card_summary');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() == 0);
        Test.stopTest();
    }
    
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerErrorsTest2(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){
            listOpportunity.get(0).sharing_code__c = 'U005';
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','Errors');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() == 0);
        Test.stopTest();
    }
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerErrorsTest2part3(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){      
            listOpportunity.get(0).sharing_code__c = 'Q002';
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() == 0);
        Test.stopTest();
    }
    
    
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerStock_GiftTest(){
        
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Batch_Log__c> batchLogs = [SELECT Id FROM Batch_Log__c];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){
            listOpportunity.get(0).sharing_code__c = 'K171';
            listOpportunity.get(0).Manual_Sharing_Code__c = true;
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','Stock_Gift');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerStock_GiftTest2(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){
            listOpportunity.get(0).sharing_code__c = 'Q001';
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','Stock_Gift');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerBequestTest(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){
            listOpportunity.get(0).sharing_code__c = 'Q002';
            listOpportunity.get(0).Manual_Sharing_Code__c = true;
            listOpportunity.get(1).sharing_code__c = 'K171';
            listOpportunity.get(1).Manual_Sharing_Code__c = true;
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','Bequest');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    Private Static void TestCash_Receipt_ReportsControllerPledge_PaymentTest(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){
            listOpportunity.get(0).sharing_code__c = 'K171';
            listOpportunity.get(0).Manual_Sharing_Code__c = true;
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','Pledge_Payment');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() == 0);
        Test.stopTest();
    }
    
    @isTest
    Private Static void TestCash_Receipt_ReportsController50kTest(){
        User usr = [SELECT Id FROM User WHERE UserName = 'testsandev@email.com'];
        List<Opportunity> listOpportunity = [SELECT Name, Type, StageName, RecordTypeId, Amount, CloseDate, Batch_Log__c, Program_Type__c,
                                                    Tax_Value__c, Tax_Date__c, High_Amount__c, Low_Amount__c, Adjustment_Code__c, Bank_Date__c, 
                                                    rC_Giving__Giving_Amount__c, rC_Giving__Ticker_Symbol__c, rC_Giving__Payment_Method__c
                                             FROM Opportunity];  
                                                 
        Test.startTest();
        System.runAs(usr){
            listOpportunity.get(0).sharing_code__c = 'K171';
            listOpportunity.get(0).Manual_Sharing_Code__c = true;
            update listOpportunity;
        }
        
        PageReference pageRef = Page.CampaignPerformanceReportingPage;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('reportType','50k');
        ApexPages.currentPage().getParameters().put('startDate',string.valueof(date1));    
        ApexPages.currentPage().getParameters().put('endDate',string.valueof(date2));
        Cash_Receipt_ReportsController cn = new Cash_Receipt_ReportsController();
        System.assert(cn.lstWrapperClass.size() > 0);
        Test.stopTest();
    }
    
    @testSetup// Method to create Test Data
    private static void createTestData(){
        UserRole testRole = new UserRole(DeveloperName = 'SandeepDev', Name = 'Test Role');
        insert testRole;
        User usr = TestUtils.createUser('test', 'testsandev@email.com', testRole.id, false);
        usr.profileId = Label.SysAdminProfileId;
        insert usr;
        
        System.runAs(usr){
            //Insert a Batch_Log__c record
            Batch_Log__c bl = new Batch_Log__c();
            bl.Batch_Log_Status__c = 'Balanced';
            bl.Name = 'NAtest';  
            bl.Batch_Log_Type__c  = 'Vendor';
            bl.Batch_Date__c = Date.newInstance(2018, 01,01);//Date.today(); 
            bl.Actual_Count__c = 500;
            bl.Expected_Count__c = 500;
            bl.Actual_Amount__c = 50000;
            bl.Expected_Amount__c = 50000;
            bl.Affiliation__c = 'NA';
            insert bl;
            
            List<Account> accList = new List<Account>();
            for (Integer i = 0; i<5; i++) {
                Account acc = TestUtils.createAccount('test',false);
                acc.AccountNumber = '12'+i;
                accList.add(acc);
            }
            insert accList;   
            List<Opportunity> listOpportunity = new  List<Opportunity>();
            for (Integer i = 0; i<5; i++) {
                Opportunity opp = TestUtils.createOpportunity(accList.get(i).id, 'TestOpp', false); 
                opp.Batch_Log__c  = bl.id;
                opp.StageName = 'Completed';
                opp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id; 
                opp.Adjustment_Code__c = 'N';
                opp.CloseDate = Date.newInstance(2018, 01,01);//System.today();
                opp.Bank_Date__c = Date.newInstance(2018, 01,01);//System.today();
                opp.Amount = 120000;
                opp.Program_Type__c = 'N';
                opp.rC_Giving__Payment_Method__c = 'Securities';        
                opp.High_Amount__c = 3000;
                opp.Low_Amount__c = 40;
                opp.Tax_Value__c = 4;
                opp.Tax_Date__c = Date.newInstance(2018, 01,01).addDays(-11);//System.today().addDays(-11);
                opp.rC_Giving__Giving_Amount__c = 1;
                opp.rC_Giving__Ticker_Symbol__c = 't';
                opp.Type = 'Nationwide Campaign';
                opp.Adjustment_Code__c = 'N';
                listOpportunity.add(opp);
            }
            insert listOpportunity;
            
            // Create CashReceiptsControls record
            TestUtils.createCashReceiptsControls('TestReceipt', 'owner@mail.com', 'sender@mail.com', 
                                                 'AAA', 'Testing', 'https://c.cs13.visual.force.com', true);
        }
    }
}
/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 19, 2017
* @description      : Test class for BatchNationalBudgetCreate
*/
@IsTest
public class BatchNationalBudgetCreateTest {        
    /*For creating test data */
    @testSetup
    public static void createTestData() {
        Map<String, Schema.RecordTypeInfo> opptyRTMap;
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        String OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        String OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        
        //Creating an non-affiliated user
        User u = TestUtils.createUser('testFirst', 'syst@testorg.com', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        
        System.runAs(u){
            //Creating record of Account
            Account acc = TestUtils.createAccount('test', true);
            //Creating record of Campaign
            Campaign camp = TestUtils.createCampaign('camp 1', false);
            camp.Package_Code__c = '101';
            camp.rC_Giving__Sub_Affiliation__c='1 - National Union';
            insert camp;
            //Creating records of Opportunity
            List<Opportunity> lstOpportunity = new List<Opportunity>();
            Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'opp1', false);
            opp1.Program_Type__c = '1';
            opp1.Amount = 500;
            opp1.StageName = 'Completed';
            opp1.Deposit_Site__c = 'NAB_NatU_Lockbox_chk/cash';
            opp1.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp1.Exclude_from_Revenue_Sharing__c = False;
            opp1.Adjustment_Code__c = 'N';
            opp1.CloseDate = System.today();
            opp1.RPT_Package_Code__c = '101';
            
            Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'opp2', false);
            opp2.Program_Type__c = '4';
            opp2.Amount = 600;
            opp2.StageName = 'Completed';
            opp2.Deposit_Site__c = 'NAP_NatFU_Pledges';
            opp2.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            opp2.Exclude_from_Revenue_Sharing__c = False;
            opp2.Adjustment_Code__c = 'N';
            opp2.Sharing_Code__c = 'Q004';
            opp2.CloseDate = System.today();
            opp2.RPT_Package_Code__c = '101';
            
            
            Opportunity opp3 = TestUtils.createOpportunity(acc.id, 'opp2', false);
            opp3.Program_Type__c = '1';
            opp3.StageName = 'Completed';
            opp3.Deposit_Site__c = 'NAP_NatFU_Pledges';
            opp3.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            opp3.Exclude_from_Revenue_Sharing__c = False;
            opp3.Adjustment_Code__c = 'N';
            opp3.CloseDate = System.today();
            opp3.Sharing_Code__c = 'U004';
            opp3.CampaignId = camp.Id;
            //opp3.RPT_Package_Code__c = null;
            
            lstOpportunity.add(opp1);
            lstOpportunity.add(opp2);
            lstOpportunity.add(opp3);
            insert lstOpportunity;
            //Creating record of National Budget Amounts
            National_Budget_Amounts__c nba = new National_Budget_Amounts__c();
            nba.Fiscal_Year__c = '2017';
            nba.Department_Code__c = '001';
            nba.Budget_Amount__c = 10101;
            nba.Budget_Category__c = 'new';
            insert nba;
            //Creating record of National Budget Report Status
            National_Budget_Report_Status__c nbrs = new National_Budget_Report_Status__c();
            nbrs.Report_Request_In_Progress__c = true;
            nbrs.Sender_Email__c = 'abc@fma.cm';
            insert nbrs;
            
        }
    }
    public static testMethod void exeuteTest() {
        System.assertEquals(0, [Select Id from National_Budget__c].size());
        List<Opportunity> lstOpportunity = [SELECT ID FROM Opportunity];
        BatchNationalBudgetCreate bnbc = new BatchNationalBudgetCreate();
        bnbc.current_YTD_EndDate = System.today().addDays(11);
        bnbc.prior_YTD_StartDate = System.today().addDays(-11);
        bnbc.prior_YTD_EndDate = System.today().addDays(1);
        bnbc.current_YTD_StartDate = System.today().addDays(-11);
        bnbc.priorFiscalYear = 2017;
        bnbc.budgetFiscalYear = 2018;
        Test.startTest();
        DataBase.executeBatch(bnbc);
        Test.stopTest();
        System.assertEquals(true, [Select Id from National_Budget__c].size()>0);
        
    }
    
    
    public static testMethod void exeuteTest1() {
        System.assertEquals(0, [Select Id from National_Budget__c].size());
        List<Opportunity> lstOpportunity  = [SELECT ID FROM Opportunity];
        BatchNationalBudgetCreate bnbc = new BatchNationalBudgetCreate();
        bnbc.current_YTD_EndDate = System.today().addDays(11);
        bnbc.prior_YTD_StartDate = System.today();
        bnbc.prior_YTD_EndDate = System.today().addDays(1);
        bnbc.current_YTD_StartDate = System.today();
        bnbc.priorFiscalYear = 2017;
        bnbc.budgetFiscalYear = 2018;
        
        Test.startTest();
        DataBase.executeBatch(bnbc);
        Test.stopTest();
        System.assertEquals(true, [Select Id from National_Budget__c].size()>0);
    }
    
}
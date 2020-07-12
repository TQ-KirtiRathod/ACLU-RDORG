/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 19, 2017
* @description      : Test class for BatchOnNationalBudgetDelete
*/
@IsTest
public class BatchOnNationalBudgetDeleteTest {
    /*For creating test data */
    @testSetup
    public static void createTestData(){
        
        //Creating an non-affiliated user
        User u = TestUtils.createUser('testFirst', 'syst@testorg.com', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        
        System.runAs(u){
            //Creating records of National Budget
            List<National_Budget__c> lstNationalBudget = TestUtils.createListNationalBudget(5);
            insert lstNationalBudget;
            //Creating record of Campaign
            Campaign camp = new Campaign();
            camp.Package_Code__c = '4';
            camp.name = 'test';
            camp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
            insert camp;
            //getting Opportunity recordtypes
            Map<String, Schema.RecordTypeInfo> opptyRTMap;
            opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
            String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
            String OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
            String OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
            String OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
            //Creating record of Account
            Account acc = TestUtils.createAccount('test', false);
            insert acc;
            //Creating an non-affiliated user
            List<Opportunity> lstOpportunity = new List<Opportunity>();
            Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'opp1', false);
            opp1.Program_Type__c = '1';
            opp1.StageName = 'Completed';
            opp1.Deposit_Site__c = 'NAB_NatU_Lockbox_chk/cash';
            opp1.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp1.Exclude_from_Revenue_Sharing__c = False;
            opp1.Adjustment_Code__c = 'N';
            opp1.CloseDate = System.today();
            opp1.RPT_Package_Code__c = '';
            Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'opp2', false);
            opp2.Program_Type__c = '4';
            opp2.StageName = 'Completed';
            opp2.Deposit_Site__c = 'NAP_NatFU_Pledges';
            opp2.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            opp2.Exclude_from_Revenue_Sharing__c = False;
            opp2.Adjustment_Code__c = 'N';
            opp2.Sharing_Code__c = 'Q004';
            opp2.CloseDate = System.today();
            Opportunity opp3 = TestUtils.createOpportunity(acc.id, 'opp2', false);
            opp3.Program_Type__c = '1';
            opp3.StageName = 'Completed';
            opp3.Deposit_Site__c = 'NAP_NatFU_Pledges';
            opp3.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            opp3.Exclude_from_Revenue_Sharing__c = False;
            opp3.Adjustment_Code__c = 'N';
            opp3.CloseDate = System.today();
            opp3.Sharing_Code__c = 'U004';
            lstOpportunity.add(opp1);
            lstOpportunity.add(opp2);
            lstOpportunity.add(opp3);
            insert lstOpportunity;
            //Creating record of National Budget Report Status
            National_Budget_Report_Status__c nbrs = National_Budget_Report_Status__c.getOrgDefaults();
            nbrs.Report_Request_In_Progress__c = true;
            nbrs.Sender_Email__c = 'test@test.com';
            upsert nbrs;
            //Creating record of National Budget Amounts
            National_Budget_Amounts__c nba = new National_Budget_Amounts__c(Fiscal_Year__c='2017', Department_Code__c='ABC',
                                                                            Budget_Category__c = 'Test', Budget_Amount__c = 343);
            insert nba;
            
        }
        
    }
    
    /*
    * for executing excute method
    */
    public static testMethod void exeuteTest(){
        List<National_Budget__c> lstNationalBudget = [SELECT ID From National_Budget__c];
        Test.startTest();
        BatchOnNationalBudgetDelete batchNationDelete = new BatchOnNationalBudgetDelete(); 
        batchNationDelete.current_YTD_StartDate = System.today();
        batchNationDelete.current_YTD_EndDate = System.today().addDays(1);
        batchNationDelete.prior_YTD_StartDate = System.today();
        batchNationDelete.prior_YTD_EndDate = System.today().addDays(1);
        batchNationDelete.priorFiscalYear = 2017;
        batchNationDelete.budgetFiscalYear =2018;
        DataBase.executeBatch(batchNationDelete);
        batchNationDelete.current_YTD_StartDate = System.today().addDays(1);
        batchNationDelete.current_YTD_EndDate = System.today().addDays(1);
        batchNationDelete.prior_YTD_StartDate = System.today();
        batchNationDelete.prior_YTD_EndDate = System.today().addDays(1);
        batchNationDelete.priorFiscalYear = 2017;
        batchNationDelete.budgetFiscalYear =2018;
        DataBase.executeBatch(batchNationDelete);
        Test.stopTest();
        system.assertEquals(0, [SELECT ID From National_Budget__c].size());
    }
    
}
/**
 * Test Class for Reconcile_UnionNonGMIReportController
 * Modified By : zenDesk : #68023*/
@isTest
private class Reconcile_UnionNonGMIReportCtrlTest {
    private static testMethod void testReconcile_UnionNonGMIReportCtrl(){
        User sysAdmin = TestUtils.createUser('Admin', 'testUser@example.com.random2', null, true);
        Account testAcc1 = TestUtils.createAccount('testAcc1', false);
        testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        testAcc1.Affiliation__c = 'AK';
        insert testAcc1;
        
        String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        list<Opportunity> oppList = new list<Opportunity>();
        Opportunity tempOpp1 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp1.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp1.Sharing_Code__c = 'R151';
        tempOpp1.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp1.stageName = 'Completed';
        tempOpp1.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp1.Exclude_from_Revenue_Sharing__c = False;
        tempOpp1.Amount = 2;
        tempOpp1.Deposit_Site__c = 'NAE_NatF_Endowment'; //'NAE - Endowment Account';   //for Line 245
        tempOpp1.Sharing_Code__c = 'E151';
        oppList.add(tempOpp1);
        
        Opportunity tempOpp2 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp2.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp2.Sharing_Code__c = 'R151';
        tempOpp2.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp2.stageName = 'Completed';
        tempOpp2.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp2.Exclude_from_Revenue_Sharing__c = False;
        tempOpp2.Amount = 2;
        tempOpp2.Deposit_Site__c = 'AK_Alaska';   //for Line 248
        tempOpp2.Sharing_Code__c = 'E151';
        oppList.add(tempOpp2);
        
        Opportunity tempOpp3 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp3.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp3.Sharing_Code__c = 'R151';
        tempOpp3.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp3.stageName = 'Completed';
        tempOpp3.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp3.Exclude_from_Revenue_Sharing__c = False;
        tempOpp3.Amount = 2;
        tempOpp3.Deposit_Site__c = 'AK_Alaska';   //for Line 252
        tempOpp3.Sharing_Code__c = 'U001';
        oppList.add(tempOpp3);
        
        Opportunity tempOpp4 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp4.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp4.Sharing_Code__c = 'R151';
        tempOpp4.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp4.stageName = 'Completed';
        tempOpp4.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp4.Exclude_from_Revenue_Sharing__c = False;
        tempOpp4.Amount = 2;
        tempOpp4.Deposit_Site__c = 'AK_Alaska';   //for Line 252
        tempOpp4.Sharing_Code__c = 'U002';
        oppList.add(tempOpp4);
        
        Opportunity tempOpp5 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp5.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp5.Sharing_Code__c = 'R151';
        tempOpp5.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp5.stageName = 'Completed';
        tempOpp5.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp5.Exclude_from_Revenue_Sharing__c = False;
        tempOpp5.Amount = 2;
        tempOpp5.Deposit_Site__c = 'AK_Alaska';   //for Line 252
        tempOpp5.Sharing_Code__c = 'U003';
        oppList.add(tempOpp5);
        
        Opportunity tempOpp6 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp6.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp6.Sharing_Code__c = 'R151';
        tempOpp6.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp6.stageName = 'Completed';
        tempOpp6.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp6.Exclude_from_Revenue_Sharing__c = False;
        tempOpp6.Amount = 2;
        tempOpp6.Deposit_Site__c = 'AK_Alaska';   //for Line 252
        tempOpp6.Sharing_Code__c = 'U004';
        oppList.add(tempOpp6);
        
        Opportunity tempOpp7 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp7.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp7.Sharing_Code__c = 'R151';
        tempOpp7.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp7.stageName = 'Completed';
        tempOpp7.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp7.Exclude_from_Revenue_Sharing__c = False;
        tempOpp7.Amount = 2;
        tempOpp7.Deposit_Site__c = 'AK_Alaska';   //for Line 264
        tempOpp7.Sharing_Code__c = 'U005';
        oppList.add(tempOpp7);
        
        Opportunity tempOpp9 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp9.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp9.Sharing_Code__c = 'E151';
        tempOpp9.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp9.stageName = 'Completed';
        tempOpp9.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp9.Exclude_from_Revenue_Sharing__c = False;
        tempOpp9.Amount = 2;
        tempOpp9.Deposit_Site__c = 'NA_CN_NoCal_NNBanked';   //for Line 252
        oppList.add(tempOpp9);
        
        Opportunity tempOpp10 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp10.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp10.Sharing_Code__c = 'E151';
        tempOpp10.Sharing_Entity_Affiliation__c = 'AK';
        tempOpp10.stageName = 'Completed';
        tempOpp10.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp10.Exclude_from_Revenue_Sharing__c = False;
        tempOpp10.Amount = 2;
        tempOpp10.Deposit_Site__c = 'AK_Alaska';   //for Line 252
        oppList.add(tempOpp10);
        
        insert oppList;
        
        Affiliate_Yearly__c testAffiliateYeary1 = TestUtils.createAffiliateYearly('testAffiliateYeary1',testAcc1.Id,'2017',false);
        testAffiliateYeary1.Foundation_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.Union_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.CMI_stage_DateEnd__c = Date.today()-2;
        testAffiliateYeary1.CMI_stage_DateStart__c = Date.today()-3;
        testAffiliateYeary1.Fiscal_Year__c = '2018';
        insert testAffiliateYeary1;
        
        System.runAs(sysAdmin){
            Income_Type_Distribution__c itd = TestUtils.createIncomeTypeDistribution(testAffiliateYeary1.Id, 'Unrestricted Bequest / Planned Gift', 20.0, false);
            String ITD_RT_TRANSACTION_Id = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Affiliate Direct Mail').getRecordTypeId();
            itd.RecordTypeId = ITD_RT_TRANSACTION_Id;
            itd.Shared_in_Advance__c = true;
            insert itd;
        }
        
        //setting the current page reference
        Test.setCurrentPage(Page.ReconciliationReport_UnionNonGMI);
        //setting the URL parameters of the page
        ApexPages.CurrentPage().getParameters().put('afid', testAffiliateYeary1.Id);
        Reconcile_UnionNonGMIReportController rung = new Reconcile_UnionNonGMIReportController();
        system.assertEquals(4, rung.two_a_total);
        system.assertEquals(4, rung.two_b_total);
        system.assertEquals(0, rung.two_c);
    }
    
    private static testMethod void testReconcile_KMUnionNonGMIReportCtrl(){
        User sysAdmin = TestUtils.createUser('Admin', 'testUser@example.com.random2', null, true);
        Account testAcc1 = TestUtils.createAccount('testAcc1', false);
        testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        testAcc1.Affiliation__c = 'KM';
        insert testAcc1;
        
        String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        list<Opportunity> oppList = new list<Opportunity>();
        Opportunity tempOpp1 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp1.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp1.Sharing_Code__c = 'C165';
        tempOpp1.Sharing_Entity_Affiliation__c = 'KM';
        tempOpp1.stageName = 'Completed';
        tempOpp1.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp1.Exclude_from_Revenue_Sharing__c = False;
        tempOpp1.Amount = 2;
        tempOpp1.Deposit_Site__c = 'KM_Kansas'; //'NAE - Endowment Account';   //for Line 245
        oppList.add(tempOpp1);
        
        Opportunity tempOpp2 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp2.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp2.Sharing_Code__c = 'C161';
        tempOpp2.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp2.stageName = 'Completed';
        tempOpp2.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp2.Exclude_from_Revenue_Sharing__c = False;
        tempOpp2.Amount = 2;
        tempOpp2.Deposit_Site__c = 'KS_Kansas';   //for Line 248
        oppList.add(tempOpp2);
       
        Opportunity tempOpp3 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp3.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp3.Sharing_Code__c = 'E131';
        tempOpp3.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp3.stageName = 'Completed';
        tempOpp3.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp3.Exclude_from_Revenue_Sharing__c = False;
        tempOpp3.Amount = 2;
        tempOpp3.Deposit_Site__c = 'NA_CN_NoCal_NNBanked';   //for Line 252
        oppList.add(tempOpp3);
         
        Opportunity tempOpp4 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp4.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp4.Sharing_Code__c = 'E131';
        tempOpp4.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp4.stageName = 'Completed';
        tempOpp4.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp4.Exclude_from_Revenue_Sharing__c = False;
        tempOpp4.Amount = 2;
        tempOpp4.Deposit_Site__c = 'NA_CN_NoCal_NNBanked';   //for Line 252
        tempOpp4.RPT_Package_Code__c = 'ABCP';
        oppList.add(tempOpp4);
        
        Opportunity tempOpp5 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp5.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp5.Sharing_Code__c = 'C161';
        tempOpp5.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp5.stageName = 'Completed';
        tempOpp5.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp5.Exclude_from_Revenue_Sharing__c = False;
        tempOpp5.Amount = 2;
        tempOpp5.Deposit_Site__c = 'KS_Kansas';   //for Line 252
        
        Opportunity tempOpp6 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp6.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp6.Sharing_Code__c = 'U005';
        tempOpp6.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp6.stageName = 'Completed';
        tempOpp6.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp6.Exclude_from_Revenue_Sharing__c = False;
        tempOpp6.Amount = 2;
        tempOpp6.Deposit_Site__c = 'NA_CN_NoCal_NNBanked';   //for Line 252
        oppList.add(tempOpp6);
        
        Opportunity tempOpp7 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp7.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp7.Sharing_Code__c = 'U004';
        tempOpp7.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp7.stageName = 'Completed';
        tempOpp7.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp7.Exclude_from_Revenue_Sharing__c = False;
        tempOpp7.Amount = 2;
        tempOpp7.Deposit_Site__c = 'NA_CN_NoCal_NNBanked';   //for Line 252
        
        Opportunity tempOpp8 = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
        tempOpp8.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        tempOpp8.Sharing_Code__c = 'E121';
        tempOpp8.Sharing_Entity_Affiliation__c = 'KS';
        tempOpp8.stageName = 'Completed';
        tempOpp8.CloseDate = Date.newInstance( 2017, 05, 01);
        tempOpp8.Exclude_from_Revenue_Sharing__c = False;
        tempOpp8.Amount = 2;
        tempOpp8.Deposit_Site__c = 'NA_CN_NoCal_NNBanked';   //for Line 252
        oppList.add(tempOpp8);
        
        
        insert oppList;
        
        Affiliate_Yearly__c testAffiliateYeary1 = TestUtils.createAffiliateYearly('testAffiliateYeary1',testAcc1.Id,'2017',false);
        testAffiliateYeary1.Foundation_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.Union_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.CMI_stage_DateEnd__c = Date.today()-2;
        testAffiliateYeary1.CMI_stage_DateStart__c = Date.today()-3;
        testAffiliateYeary1.Fiscal_Year__c = '2018';
        insert testAffiliateYeary1;
        
        System.runAs(sysAdmin){
            Income_Type_Distribution__c itd = TestUtils.createIncomeTypeDistribution(testAffiliateYeary1.Id, 'Unrestricted Bequest / Planned Gift', 20.0, false);
            String ITD_RT_TRANSACTION_Id = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Affiliate Direct Mail').getRecordTypeId();
            itd.RecordTypeId = ITD_RT_TRANSACTION_Id;
            itd.Shared_in_Advance__c = true;
            insert itd;
        }
        
        //setting the current page reference
        Test.setCurrentPage(Page.ReconciliationReport_UnionNonGMI);
        //setting the URL parameters of the page
        ApexPages.CurrentPage().getParameters().put('afid', testAffiliateYeary1.Id);
        Reconcile_UnionNonGMIReportController rung = new Reconcile_UnionNonGMIReportController();
        //system.assertEquals(2, rung.two_a_total);
        //system.assertEquals(2, rung.two_b_total);
        //system.assertEquals(0, rung.two_c);
    }

}
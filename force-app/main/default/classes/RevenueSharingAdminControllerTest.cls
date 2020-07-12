/**
 * Test Class for RevenueSharingAdminController
 **/ 
@isTest
private class RevenueSharingAdminControllerTest {
    public static Affiliate_Yearly__c testAffiliateYeary1 = new Affiliate_Yearly__c();
    public static Affiliate_Yearly__c testAffiliateYeary2 = new Affiliate_Yearly__c();
    private static testMethod void testRevenueSharingAdminController(){
        //setting the current page reference
        Test.setCurrentPage(Page.Revenue_Sharing_Admin);
        //setting the URL parameters of the page
        
        RevenueSharingAdminController rsad = new RevenueSharingAdminController();
        rsad.affiliateYearly = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c,
                                   CMI_stage_DateEnd__c,CMI_stage_DateStart__c,Fiscal_Year__c
                                   FROM Affiliate_Yearly__c
                                   WHERE name='testAffiliateYeary1'][0];
            
        rsad.selectedReportType = 'CMI';
        rsad.save();
        
        National_Fiscal_Year__c updatedNFY = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c
                                              FROM National_Fiscal_Year__c
                                              WHERE name='2018'][0];
        
        System.assertEquals(0.1000,updatedNFY.Foundation_Cost_Factor__c);
        System.assertEquals(0.3000,updatedNFY.Union_Cost_Factor__c);
        
        //Test for condition in which selectedReportType != 'CMI' (means it is FCMI)
        //AND validation() returns true
        rsad = new RevenueSharingAdminController();
        rsad.affiliateYearly = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c,
                                   CMI_stage_DateEnd__c,CMI_stage_DateStart__c,Fiscal_Year__c
                                   FROM Affiliate_Yearly__c
                                   WHERE name='testAffiliateYeary1'][0];
        rsad.selectedReportType = 'FCMI';
        rsad.save();
        System.assertEquals(false,rsad.isShowError);
        
        //further conditions for else coverage
        Affiliate_Yearly__c affiliateYearly1 = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c
                                                FROM Affiliate_Yearly__c
                                                WHERE name='testAffiliateYeary1'][0];
        affiliateYearly1.Foundation_Cost_Factor__c = null;
        update affiliateYearly1;
        rsad = new RevenueSharingAdminController();
        rsad.affiliateYearly = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c,
                                   CMI_stage_DateEnd__c,CMI_stage_DateStart__c,Fiscal_Year__c
                                   FROM Affiliate_Yearly__c
                                   WHERE name='testAffiliateYeary1'][0];
        rsad.selectedReportType = 'FCMI';
        rsad.save();
        System.assertEquals(true,rsad.isShowError);
        
        affiliateYearly1 = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c
                            FROM Affiliate_Yearly__c
                            WHERE name='testAffiliateYeary1'][0];
        affiliateYearly1.Foundation_Cost_Factor__c = 0;
        update affiliateYearly1;
        rsad = new RevenueSharingAdminController();
        rsad.affiliateYearly = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c,
                                   CMI_stage_DateEnd__c,CMI_stage_DateStart__c,Fiscal_Year__c
                                   FROM Affiliate_Yearly__c
                                   WHERE name='testAffiliateYeary1'][0];
        rsad.selectedReportType = 'FCMI';
        rsad.save();
        System.assertEquals(true,rsad.isShowError);
        
        affiliateYearly1 = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c
                            FROM Affiliate_Yearly__c
                            WHERE name='testAffiliateYeary1'][0];
        affiliateYearly1.CMI_stage_DateEnd__c = Date.today().addDays(2);
        affiliateYearly1.Foundation_Cost_Factor__c = 0.2000;
        update affiliateYearly1;
        rsad = new RevenueSharingAdminController();
        rsad.affiliateYearly = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c,
                                   CMI_stage_DateEnd__c,CMI_stage_DateStart__c,Fiscal_Year__c
                                   FROM Affiliate_Yearly__c
                                   WHERE name='testAffiliateYeary1'][0];
        rsad.save();
        System.assertEquals(true,rsad.isShowError);
    }
    private static testMethod void testRevenueSharingAdminController2(){
        //createData();
        //setting the current page reference
        Test.setCurrentPage(Page.Revenue_Sharing_Admin);
        //setting the URL parameters of the page
        ApexPages.CurrentPage().getParameters().put('affId', testAffiliateYeary2.Id);
        
        RevenueSharingAdminController rsad = new RevenueSharingAdminController();
        
        rsad.affiliateYearly = [SELECT id,name,Foundation_Cost_Factor__c,Union_Cost_Factor__c,
                                   CMI_stage_DateEnd__c,CMI_stage_DateStart__c,Fiscal_Year__c
                                   FROM Affiliate_Yearly__c
                                   WHERE name='testAffiliateYeary2'][0];
            
        rsad.isDonorMemberCount = true;
        rsad.selectedReportType = 'Donor-Member Count';
        rsad.save();
        system.assertEquals(rsad.affiliateYearly.CMI_stage_DateStart__c, [SELECT Member_Donor_Count_From_Date__c FROM Affiliate_Yearly__c WHERE Id = :rsad.affiliateYearly.Id].Member_Donor_Count_From_Date__c);
        system.assertEquals(rsad.affiliateYearly.CMI_stage_DateEnd__c, [SELECT Member_Donor_Count_To_Date__c FROM Affiliate_Yearly__c WHERE Id = :rsad.affiliateYearly.Id].Member_Donor_Count_To_Date__c);
    }
    @testSetup
    private static void createData(){
        National_Fiscal_Year__c natFiscal = TestUtils.createFiscalyearCSData('2018', '2018', 0, 0, 0, false);
        natFiscal.Foundation_Cost_Factor__c = 0.1000;
        natFiscal.Percent_GMI_Affiliates__c = 0.2000;
        natFiscal.Union_Cost_Factor__c = 0.3000;
        insert natFiscal;
        
        Revenue_Sharing_Sytem_Controls__c revSh = new Revenue_Sharing_Sytem_Controls__c();
        revSh.name = 'testRevenueShSysCtrl';
        revSh.Report_Request_Owner_Email__c = UserInfo.getUserEmail();
        revSh.Report_Request_In_Progress__c = true;
        revSh.Salesforce_Base_URL__c = URL.getSalesforceBaseUrl().toExternalForm();
        insert revSh;
        
        Account testAcc1 = TestUtils.createAccount('testAcc1', false);
        testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
		testAcc1.Affiliation__c = 'AK';
        insert testAcc1;
        
        
        //Following data according to save method functionality 
        list<Affiliate_Yearly__c> affList = new list<Affiliate_Yearly__c>();
        testAffiliateYeary1 = TestUtils.createAffiliateYearly('testAffiliateYeary1',testAcc1.Id,'2017',false);
        testAffiliateYeary1.Foundation_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.Union_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.CMI_stage_DateEnd__c = Date.today()-2;
        testAffiliateYeary1.CMI_stage_DateStart__c = Date.today()-3;
        testAffiliateYeary1.Fiscal_Year__c = '2018';
        affList.add(testAffiliateYeary1);
        
        testAffiliateYeary2 = TestUtils.createAffiliateYearly('testAffiliateYeary2',testAcc1.Id,'2017',false);
        testAffiliateYeary2.Foundation_Cost_Factor__c = 0.2000;
        testAffiliateYeary2.Union_Cost_Factor__c = 0.2000;
        testAffiliateYeary2.CMI_stage_DateEnd__c = Date.today()-2;
        testAffiliateYeary2.CMI_stage_DateStart__c = Date.today()-4;
        testAffiliateYeary2.Fiscal_Year__c = '2019';
        affList.add(testAffiliateYeary2);
        insert affList;
    }
}
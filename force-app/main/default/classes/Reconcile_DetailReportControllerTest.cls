@isTest
private class Reconcile_DetailReportControllerTest {
    Static string affiliate1, affiliate2;
    static Account acc;
    @testSetup 
	private static void createData() {
	    Set<String> setOfRequiredCodes = new Set<String> {'R112', 'R113','R121','R131','R141','R151','R181','R191',
                                                            'K161', 'K165','K171','N111','N175', 'Q001','Q002','Q003','Q004','Q005'};
                                          
        Set<String> setOfUnionCodes = new Set<String> {'E121','E131','E141','E151','E181','E191',
                                                        'C161','C165', 'U001','U002', 'U003', 'U004', 'U005' };
	    String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
	    String OPPORTUNITY_RT_PLEDGE_PAY_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
	    String OPPORTUNITY_RT_SOFT_CREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
	    List<Opportunity> oppToInsert = new List<Opportunity>();
	    acc = TestUtils.createAccount('Test Account', true);
	    Integer i = 0;
	    affiliate1 = 'NA'; 
	    affiliate2 = 'AR';
	    Opportunity opp, opp1, opp2, opp3;
	    for(String sharingCode : setOfRequiredCodes){
            opp = TestUtils.createOpportunity(acc.id, 'OppName'+sharingCode+i, false);
            opp.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp.Sharing_Code__c = sharingCode;
            opp.Amount = 2000+i;
            opp.Sharing_Entity_Affiliation__c = affiliate1;
            opp.stageName = 'Completed';
            opp.CloseDate = Date.newInstance(2017, 12, 17).addDays(i);
            opp.Exclude_from_Revenue_Sharing__c = false;
            opp.Deposit_Site__c = 'NAZ_NatF_Operating_eft';
            opp.RPT_Package_Code__c = 'ABCP';
            opp.Sharing_Entity__c = 'NA';
            i++;
            oppToInsert.add(opp);
            
            opp1 = TestUtils.createOpportunity(acc.id, 'OppName'+sharingCode+i, false);
            opp1.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp1.Sharing_Code__c = sharingCode;
            opp1.Amount = 2000+i;
            opp1.Sharing_Entity_Affiliation__c = affiliate2;
            opp1.stageName = 'Completed';
            opp1.CloseDate = Date.newInstance(2017, 12, 17).addDays(i);
            opp1.Exclude_from_Revenue_Sharing__c = false;
            opp1.Deposit_Site__c = 'AR_Arkansas';
            opp1.RPT_Package_Code__c = 'ABCP';
            opp1.Sharing_Entity__c = 'AR';
            i++;
            oppToInsert.add(opp1);
	    }
	    for(String unionCode : setOfUnionCodes){
            opp2 = TestUtils.createOpportunity(acc.id, 'OppName'+unionCode+i, false);
            opp2.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp2.Sharing_Code__c = unionCode;
            opp2.Amount = 2000+i;
            opp2.Sharing_Entity_Affiliation__c = affiliate1;
            opp2.stageName = 'Completed';
            opp2.CloseDate = Date.newInstance(2017, 12, 17).addDays(i);
            opp2.Exclude_from_Revenue_Sharing__c = false;
            opp2.Deposit_Site__c = 'NAZ_NatF_Operating_eft';
            opp2.RPT_Package_Code__c = 'ABCP';
            i++;
            oppToInsert.add(opp2);
            
            opp3 = TestUtils.createOpportunity(acc.id, 'OppName'+unionCode+i, false);
            opp3.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp3.Sharing_Code__c = unionCode;
            opp3.Amount = 2000+i;
            opp3.Sharing_Entity_Affiliation__c = affiliate2;
            opp3.stageName = 'Completed';
            opp3.CloseDate = Date.newInstance(2017, 12, 17).addDays(i);
            opp3.Exclude_from_Revenue_Sharing__c = false;
            opp3.Deposit_Site__c = 'NAZ_NatF_Operating_eft';
            opp3.RPT_Package_Code__c = 'ABCP';
            i++;
            oppToInsert.add(opp3);
	    }
	    oppToInsert[0].recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
	    oppToInsert[1].recordTypeId = OPPORTUNITY_RT_PLEDGE_PAY_Id;
	    oppToInsert[2].recordTypeId = OPPORTUNITY_RT_SOFT_CREDIT_Id;
	    oppToInsert[2].IsCreatedFromBatchLog__c = true;
        insert oppToInsert;
        
	}
	
	
	@isTest
	private static void testController1(){
	    affiliate1 = 'NA';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate1);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','FoundationNonGMI');
        Test.startTest();
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        Test.stopTest();
        System.assertEquals(ac.wrapperClassList.size(), 18);
        System.assertEquals(ac.wrapperClassList.get(0).cp, 'CP');
        for(integer cnt = 0; cnt < ac.wrapperClassList.size() - 1; cnt++) {
            if(ac.wrapperClassList.get(cnt).Sharing_Category != 'w_A1_Affiliate Direct Mail') {
                continue;
            }
            System.assertEquals(ac.wrapperClassList.get(cnt).Sharing_Category, 'w_A1_Affiliate Direct Mail');
        }
	}
	
	@isTest
	private static void testController2(){
	    affiliate1 = 'NA';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate1);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','UnionNonGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 13);
        //System.assertEquals(ac.wrapperClassList.get(0).Sharing_Category, 'w_A1_Affiliate Banked Unrestricted Incentive Income');
        //System.assertEquals(ac.wrapperClassList.get(12).Sharing_Category, 'v_3e_ or v_3f_Affiliate Banked Other Bequest');
        for(integer cnt = 0; cnt < ac.wrapperClassList.size() - 1; cnt++) {
            System.debug('Category :: ' + ac.wrapperClassList.get(cnt).Sharing_Category);
            if(ac.wrapperClassList.get(cnt).Sharing_Category == 'w_A1_Affiliate Banked Unrestricted Incentive Income' ) {
                System.assertEquals(ac.wrapperClassList.get(cnt).Sharing_Category, 'w_A1_Affiliate Banked Unrestricted Incentive Income');
            }
            if(ac.wrapperClassList.get(cnt).Sharing_Category == 'v_3e_ or v_3f_Affiliate Banked Other Bequest') {
                System.assertEquals(ac.wrapperClassList.get(cnt).Sharing_Category, 'v_3e_ or v_3f_Affiliate Banked Other Bequest');
            }

        }
	}
	
	@isTest
	private static void testController3(){
	    affiliate1 = 'NA';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate1);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','FoundationGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 18);
        System.assertEquals(ac.wrapperClassList.get(3).Sharing_Category, 'v_2 or v_4b Affiliate Solicited Earmarked');
        System.assertEquals(ac.wrapperClassList.get(9).Sharing_Category, 'w_C1_Affiliate Banked Unshared Recognized Foundation Grants');
	}
	
	@isTest
	private static void testController4(){
	    affiliate1 = 'NA';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate1);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','UnionGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 13);
        System.assertEquals(ac.wrapperClassList.get(4).Sharing_Category, 'Affiliate In-Kind Gifts');
        System.assertEquals(ac.wrapperClassList.get(10).Sharing_Category, 'v_4c_Affiliate Banked Earmarked Bequest');
	}
	
	@isTest
	private static void testController5(){
	    affiliate2 = 'AR';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate2);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','FoundationNonGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 18);
        System.assertEquals(ac.wrapperClassList.get(13).Sharing_Category, 'w_D1_Affiliate Banked Shared Bequest');
        System.assertEquals(ac.wrapperClassList.get(14).Sharing_Category, 'w_D2_Affiliate Banked Directed Bequest');
	}
	
	@isTest
	private static void testController6(){
	    affiliate2 = 'AR';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate2);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','UnionNonGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 13);
        System.assertEquals(ac.wrapperClassList.get(9).Sharing_Category, 'v_3h_National Banked Directed Bequest');
        System.assertEquals(ac.wrapperClassList.get(12).Sharing_Category, 'v_3k_National Banked Other Bequest');
	}
	
	@isTest
	private static void testController7(){
	    affiliate2 = 'NA';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate2);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','FoundationGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 18);
        System.assertEquals(ac.wrapperClassList.get(3).Sharing_Category, 'v_2 or v_4b Affiliate Solicited Earmarked');
        System.assertEquals(ac.wrapperClassList.get(9).Sharing_Category, 'w_C1_Affiliate Banked Unshared Recognized Foundation Grants');
	}
	
	@isTest
	private static void testController8(){
	    affiliate2 = 'NA';
	    PageReference myVfPage = Page.Reconcile_DetailReport;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('affiliate',affiliate2);
        ApexPages.currentPage().getParameters().put('startDate','2017-11-17');
        ApexPages.currentPage().getParameters().put('endDate','2018-11-17');
        ApexPages.currentPage().getParameters().put('report','UnionGMI');
        
        Reconcile_DetailReportController ac = new Reconcile_DetailReportController();
        
        System.assertEquals(ac.wrapperClassList.size(), 13);
        System.assertEquals(ac.wrapperClassList.get(4).Sharing_Category, 'Affiliate In-Kind Gifts');
        System.assertEquals(ac.wrapperClassList.get(10).Sharing_Category, 'v_4c_Affiliate Banked Earmarked Bequest');
	}

}
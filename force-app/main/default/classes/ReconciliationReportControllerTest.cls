/**
 * Test Class for ReconciliationReportController
 **/
@isTest
private class ReconciliationReportControllerTest {
    public static List<Affiliate_Yearly__c> affiliateYearlyList;
    @isTest
    private static void testReconciliationReportController(){
        createData();
        affiliateYearlyList.get(0).Eligible_for_GMI__c=true;
        insert affiliateYearlyList;
        Test.startTest();        
        PageReference pageRef = Page.ReconciliationReport_Foundation;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('afid',affiliateYearlyList.get(0).id);
        ReconciliationReportController rrc=new ReconciliationReportController();
        PageReference pg = rrc.redirectReconciliationReportUnion();
        system.assert(pg.getUrl().contains('Reconcile_UnionGMIReportPage'));
        pg = rrc.redirectReconciliationReportFoundationGMI();
        system.assert(pg.getUrl().contains('Reconcile_FoundationGMIReportPage'));
        Test.stopTest();
    } 
    
    @isTest
    private static void testReconciliationReportController1(){
        createData();
        affiliateYearlyList.get(0).Eligible_for_GMI__c=False;
        insert affiliateYearlyList;
        Test.startTest();
        PageReference pageRef = Page.ReconciliationReport_Union;  
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('afid',affiliateYearlyList.get(0).id);        
        ReconciliationReportController rrc=new ReconciliationReportController();
        PageReference pg = rrc.redirectReconciliationReportUnion();
        system.assert(pg.getUrl().contains('Reconcile_UnionNonGMIReportPage'));
        pg = rrc.redirectReconciliationReportFoundationGMI();
        system.assert(pg.getUrl().contains('Reconcile_FoundationNonGMIReportPage'));
        Test.stopTest();
    }
    
    
    public static void createData(){
        list<Account> accList = new list<Account>();
        String recType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        for(integer i=0; i<5; i++){
            Account acc = TestUtils.createAccount('test', false);
            acc.RecordTypeId=recType;
            acc.Affiliation__c = 'AA';
            accList.add(acc);
        }
        insert accList;
        affiliateYearlyList = new List<Affiliate_Yearly__c>();
        for(Integer i=0; i<5; i++){
        	Affiliate_Yearly__c ay = TestUtils.createAffiliateYearly('Test yearly', accList[i].Id, '2017', false);
        	affiliateYearlyList.add(ay);
        }
    }
}
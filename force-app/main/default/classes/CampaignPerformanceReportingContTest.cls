/**
 * Test Class for CampaignPerformanceReportingController
 **/
@isTest
private class CampaignPerformanceReportingContTest {
    public static List<Opportunity> listAggregateResult;
    public static Id donationRec = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    public static Id PledgeRec = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
	public static Campaign objCampaign;
 @isTest
    Private static void TestCampaignPerformanceReportingController(){
        createData(10);                
        PageReference pageRef = Page.CampaignPerformanceReportingPage;	
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pv1','AK - ACLU of Alaska');
        ApexPages.currentPage().getParameters().put('pv2','1 - National Union');	
        ApexPages.currentPage().getParameters().put('pv3','A - Affiliate Membership');
        ApexPages.currentPage().getParameters().put('pv4','Basic Membership');    
        ApexPages.currentPage().getParameters().put('pv5','Acquisition');    
        ApexPages.currentPage().getParameters().put('pv6','Advertising');    
        ApexPages.currentPage().getParameters().put('pv7','00');    

        CampaignPerformanceReportingController cmp = new CampaignPerformanceReportingController();	
        cmp.displayReport();
        PageReference pg = cmp.displayExcel();
        system.assert(pg.getUrl().contains('CampaignPerformanceRatingExcel'));
    }
@isTest
    Private static void TestCampaignPerformanceReportingController2(){
        createData(1);                
        PageReference pageRef = Page.CampaignPerformanceReportingPage;	
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pv1','NGO');
        ApexPages.currentPage().getParameters().put('pv2','5 - Affiliate Foundation');	
        ApexPages.currentPage().getParameters().put('pv3','A - Affiliate Membership');
        ApexPages.currentPage().getParameters().put('pv4','Basic Membership');    
        ApexPages.currentPage().getParameters().put('pv5','Acquisition');    
        ApexPages.currentPage().getParameters().put('pv6','Advertising');    
        ApexPages.currentPage().getParameters().put('pv7','00');    

        CampaignPerformanceReportingController cmp = new CampaignPerformanceReportingController();	
        cmp.displayReport();
        system.assert(cmp.repWrapper.size() > 0);
        cmp.displayExcel();
    }
    
    @isTest
    Private static void TestCampaignPerformanceReportingController3(){
        createData(3);                
        PageReference pageRef = Page.CampaignPerformanceReportingPage;	
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pv1','NGO');
        ApexPages.currentPage().getParameters().put('pv2','5 - Affiliate Foundation');	
        ApexPages.currentPage().getParameters().put('pv3','A - Affiliate Membership');
        ApexPages.currentPage().getParameters().put('pv4','Basic Membership');    
        ApexPages.currentPage().getParameters().put('pv5','Acquisition');    
        ApexPages.currentPage().getParameters().put('pv6','Advertising');    
        ApexPages.currentPage().getParameters().put('pv7','00');    

        CampaignPerformanceReportingController cmp = new CampaignPerformanceReportingController();	
        cmp.displayReport();
        system.assert(cmp.repWrapper.size() > 0);
        cmp.displayExcel();
    }
    public static void createData(integer oppCount){
        User sysAdmin = TestUtils.createUser('sysAdmin', 'testUser@email.com.random1', null, true);
        listAggregateResult = new List<Opportunity>();
        
        objCampaign=TestUtils.createCampaign('test',False);
        objCampaign.rC_Giving__Affiliation__c='NGO';
        objCampaign.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        objCampaign.rC_Giving__Campaign_Type__c='A - Affiliate Membership';
        objCampaign.rC_Giving__Appeal_Segment__c='Basic Membership';
        objCampaign.rC_Giving__Solicitation_Type__c='Acquisition';
        objCampaign.rC_Giving__Channel__c='Advertising';
        objCampaign.rC_Giving__Effort__c='00'; 
        System.runAs(sysAdmin){
            insert objCampaign;
        }
        Account ac = TestUtils.createAccount('test',true);
        for(Integer i=0;i<oppCount;i++){
            Opportunity obj = TestUtils.createOpportunity(ac.id,'Test'+i,False);
            obj.CloseDate=Date.today().addDays(i);
            obj.RecordTypeId=donationRec;
            obj.CampaignId=objCampaign.Id;
            listAggregateResult.add(obj);
        }
        insert listAggregateResult;
    }
}
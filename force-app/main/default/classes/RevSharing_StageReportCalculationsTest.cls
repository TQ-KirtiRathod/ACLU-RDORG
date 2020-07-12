/**
 * Test Class for RevSharing_StageReportCalculations
 **/
@isTest
private class RevSharing_StageReportCalculationsTest {
    private static List<Affiliate_Yearly__c> affiliateYearlyList;
    private static Id ayId;
    
    //Create test data
    public static void setup(){
        Account acc = TestUtils.createAccount('test', false);
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        acc.Affiliation__c = 'AA';
        insert acc;
        affiliateYearlyList = new List<Affiliate_Yearly__c>();
        //for(integer i=0; i<10; i++){
    	Affiliate_Yearly__c ay = TestUtils.createAffiliateYearly('Test yearly', acc.Id, '2017', false);
        affiliateYearlyList.add(ay);
        //}
        insert affiliateYearlyList;
        
        Monthly_Cash_Receipts_Controls__c cs = new Monthly_Cash_Receipts_Controls__c();
        cs.Name = 'Monthly Cash Receipt Controls';
        //cs.Batch_Summary_Report_Id__c = '00OW0000000HSEK';
        //cs.Credit_Card_Batches_Report_Id__c='00OW0000000HSH9';
        cs.Salesforce_Base_URL__c = 'https://c.cs13.visual.force.com';
        insert cs;
        
        Revenue_Sharing_Sytem_Controls__c rs = new Revenue_Sharing_Sytem_Controls__c();
        rs.Name ='Revenue';
        rs.Salesforce_Base_URL__c='https://c.cs13.visual.force.com';
        insert rs;
        
    }
    
    @isTest
    static void testMethod1(){
        setup();
        Test.startTest();
        RevSharing_StageReportCalculations.generateCMI_FCMI_Report(affiliateYearlyList,'CMI');
        RevSharing_StageReportCalculations.generateCMI_FCMI_Report(affiliateYearlyList,'FCMI');
       	RevSharing_StageReportCalculations.sendEmail('batch_Credit_Card_summary', 'test@test.com', 'test@test.com', '2017');
        RevSharing_StageReportCalculations.sendEmail('FCMI', 'test@test.com', 'test@test.com', '2017');
        Test.stopTest();
        List<AsyncApexJob> aap = [SELECT  Status, ApexClassId, ApexClass.Name  FROM AsyncApexJob WHERE ApexClass.Name = 'RevSharing_CMICalculator'];
        //assert to check if batch is completed 
        system.assertEquals('Completed', aap[0].Status);
        
    }
	
}
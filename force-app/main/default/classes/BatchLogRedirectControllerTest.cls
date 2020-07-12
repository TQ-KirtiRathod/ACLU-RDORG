/*
*
*Name  :  BatchLogRedirectControllerTest
*Author:  Appirio India (Shobhit Pant)
*Date  :  June 13, 2017
*Purpose : Test Class for BatchLogRedirectController class
*
*/
@isTest
private class BatchLogRedirectControllerTest {
    static Batch_Log__c testBatchLog1;
    static Map<String,Schema.RecordTypeInfo> blRTMap;
	@isTest
	private static void testRedirect(){
	    createTestData();
		//RecordType - Vendor
	    String BATCH_LOG_RT_VENDOR_Id = blRTMap.get('Vendor').getRecordTypeId();

	    Test.startTest();

	    //creating standardcontroller object to pass as parameter to controller constructor
	    ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
	    BatchLogRedirectController batchLogContObj = new BatchLogRedirectController(sc);  

	    //setting vf page as current test page for passing parameters
	    PageReference pageRef = Page.BatchLogRedirectPage;
	    Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', testBatchLog1.Id);
        //calling the redirect method
        PageReference pageRef1 = BatchLogRedirectController.redirect();
        system.assert(pageRef1.getUrl().contains('BatchLogDetailPage'));
        //updating the recordtype of batchlog record for covering else part of the constructor method
        testBatchLog1.RecordTypeId = BATCH_LOG_RT_VENDOR_Id;
        update testBatchLog1;

	    ApexPages.currentPage().getParameters().put('id', testBatchLog1.Id);
        pageRef1 = BatchLogRedirectController.redirect();
        system.assert(pageRef1.getUrl().contains('nooverride'));
        
        Test.stopTest();
	}
	
	@isTest
	private static void testEditRedirect(){
	    createTestData();
		//RecordType - Vendor
	    String BATCH_LOG_RT_VENDOR_Id = blRTMap.get('Vendor').getRecordTypeId();

	    Test.startTest();
	    
	    //creating standardcontroller object to pass as parameter to controller constructor
	    ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
	    BatchLogRedirectController batchLogContObj = new BatchLogRedirectController(sc);  

	    //setting vf page as current test page for passing parameters
	    PageReference pageRef = Page.BatchLogRedirectPage;
	    Test.setCurrentPage(pageRef);
        String objPrefix = Batch_Log__c.sobjecttype.getDescribe().getKeyPrefix();
        ApexPages.currentPage().getParameters().put('retURL', objPrefix);
        ApexPages.currentPage().getParameters().put('id', testBatchLog1.Id);
        //calling the redirect method
        BatchLogRedirectController.editRedirect();

        //updating the recordtype of batchlog record for covering else part of the constructor method
        testBatchLog1.RecordTypeId = BATCH_LOG_RT_VENDOR_Id;
        update testBatchLog1;
        
	    ApexPages.currentPage().getParameters().put('id', testBatchLog1.Id);
        PageReference pageRef1 = BatchLogRedirectController.editRedirect();
        system.assert(pageRef1.getUrl().contains('nooverride'));
        Test.stopTest();
	}
	
	static void createTestData() {
	    //fetching RecordTypeIds of Batch_Log__c using Schema class
		blRTMap = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName();
		//RecordType - Manual
	    String BATCH_LOG_RT_MANUAL_Id = blRTMap.get('Manual').getRecordTypeId();
	    //creating Batch Log record using TestUtils class
	    testBatchLog1 = TestUtils.createBatchLog('testBatchName1', false);
	    //adding date to avoid onbeforeinsert trigger exception
	    testBatchLog1.Batch_Date__c = Date.today();
	    testBatchLog1.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
	    insert testBatchLog1;
	}
}
/*
*
*Name  :  BatchLogSummariesDeleteBatchTest 
*Author:  Appirio : Shobhit Pant
*Date  :  June 14, 2017
*Purpose : Test Class for BatchLogSummariesDeleteBatch Class
*/
@isTest
public class BatchLogSummariesDeleteBatchTest {
	@isTest
	static void testDeleteBatchLogSummaries(){
		Test.startTest();
		createData(10);
		Date startDate = Date.today().addDays(-1);
		Date endDate = Date.today();
		Database.executeBatch(new BatchLogSummariesDeleteBatch(startDate, endDate, 'Errors'));
		//Calling the class again once all the log summaries are deleted (increasing coverage)
		Database.executeBatch(new BatchLogSummariesDeleteBatch(startDate, endDate, 'Errors'));
		Test.stopTest();
		system.assertEquals(true, [SELECT Id FROM Batch_Log_Summary__c].isEmpty());

	}
	static void createData(Integer count){
		//test custom setting
		Monthly_Cash_Receipts_Controls__c cashRecpCustSetObj = TestUtils.createCashReceiptsControls('testcustsett','saikrishna.tavva@appirio.com','saikrishna.tavva@appirio.com','','','https://c.cs13.visual.force.com',true);

		List<Batch_Log_Summary__c> blsList = new List<Batch_Log_Summary__c>();
		for(Integer i = 0; i < count ; i++){
			Batch_Log_Summary__c bls = TestUtils.createBatchLogSummary('testbls', false);
			blsList.add(bls);
		}
		if(blsList.size()>0){
			insert blsList;
		}
	}

}
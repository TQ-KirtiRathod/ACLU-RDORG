/*
*
*Name  :  BatchPopulatePlannedGivingForGoLiveTest 
*Author:  Appirio : Shobhit Pant
*Date  :  June 14, 2017
*Purpose : Test Class for BatchPopulatePlannedGivingForGoLive Class
*/
@isTest
public class BatchPopulatePlannedGivingForGoLiveTest {
	
	@isTest 
	static void testBatchPopulatePlannedGiving(){
		createData();
		//Executing the batchable class
		Test.StartTest();
		Database.executeBatch(new BatchPopulatePlannedGivingForGoLive());
		Test.StopTest();

		Date d = Date.newInstance(2015, 3, 15);
		System.assertEquals(161248.91, [SELECT Rpt_Estimated_Average_Giving_Amount__c 
			                              FROM rC_Giving__Planned_Giving__c 
			                              WHERE Gift_Date__c = :d ].get(0).Rpt_Estimated_Average_Giving_Amount__c);
	}


	//method to create required data
	static void createData(){
		List<rC_Giving__Planned_Giving__c> pgList = new List <rC_Giving__Planned_Giving__c>();
		for(Integer i = 0; i < 4; i++){
			rC_Giving__Planned_Giving__c plannedGiving = TestUtils.createPlannedGiving(null,null,false);
            plannedGiving.Name = 'testPlanned Giving' + i;
			pgList.add(plannedGiving);
		}
		//changing planned giving Contract Date values (to increase code coverage)
		if(pgList.size() == 4){
			pgList.get(0).Gift_Date__c = Date.newInstance(2015, 3, 15);
			pgList.get(1).Gift_Date__c = Date.newInstance(2015, 5, 15);
			pgList.get(2).Gift_Date__c = Date.newInstance(2017, 3, 15);
			pgList.get(3).Gift_Date__c = Date.newInstance(2017, 5, 15);
			insert pgList;
		}
	}
}
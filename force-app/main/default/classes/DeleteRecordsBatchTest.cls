/*
*
*Name  :  DeleteRecordsBatchTest
*Author:  Appirio India 
*Purpose : Test Class for Delete_Records_Batch
*
*/
@isTest
public class DeleteRecordsBatchTest {
	
    static testMethod void testDeleteRecordsBatch() { 
    	
		List<rC_Bios__Contact_Address__c> lstConAdd= new List<rC_Bios__Contact_Address__c>();
		
		// Contact Record
        Contact rcCon = new Contact(LastName = 'testCon1');
        insert rcCon;
        
        // Contact Address Record
		for(Integer i=0 ;i <200;i++) {
            lstConAdd.add(TestUtils.createContactAddress(null,rcCon.Id,false));
		}
		
		insert lstConAdd;
		
		Test.startTest(); 
			Delete_Records_Batch obj = new Delete_Records_Batch('SELECT Id FROM rC_Bios__Contact_Address__c'); 
			DataBase.executeBatch(obj); 
			
	        obj = new Delete_Records_Batch('SELECT Id FROM rC_Bios__Account_Address__c'); 
			DataBase.executeBatch(obj);
			
		Test.stopTest(); 
		system.assertEquals(0, [SELECT Id FROM rC_Bios__Contact_Address__c].size());
		system.assertEquals(0, [SELECT Id FROM rC_Bios__Contact_Address__c].size());
	}
}
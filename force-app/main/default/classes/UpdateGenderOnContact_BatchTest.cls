/*
*Author:  Appirio India 
*Date  :  October 
*Purpose : Test Coverage for UpdateGenderOnContact_Batch Class
*/
@isTest
private class UpdateGenderOnContact_BatchTest {
	
	/* 
    *
    * Method testUpdateGenderOnContact_Batch
    * Testing UpdateGenderOnContact_Batch functionality
    */
    private static testMethod void testUpdateGenderOnContact_Batch() {
		createTestData();
        Test.startTest();

            UpdateGenderOnContact_Batch obj = new UpdateGenderOnContact_Batch();
            DataBase.executeBatch(obj); 
            
        Test.stopTest();
        
        Integer unKnownCons = 0, femaleContacts = 0;
        for(Contact con: [	SELECT id, name, Salutation, rC_Bios__Gender__c
                         	FROM Contact ]) {
            if(con.rC_Bios__Gender__c != 'Male' && con.rC_Bios__Gender__c != 'Female'){
                ++unKnownCons;
            } else if(con.rC_Bios__Gender__c == 'Female') {
            	++femaleContacts;
            }
        }
        System.assertEquals(11, unKnownCons);
        System.assertEquals(9, femaleContacts);
    }
    
    /* 
    *
    * Method createTestData
    * Creating Test Data
    */
    private static void createTestData() {
    	List<Contact> conList = new List<Contact>();
        List<Gender_Names__c> genderNameList = new List<Gender_Names__c>();
        Datetime dt = DateTime.now()-2;
        
        // Account Records
        Account testAcc1 = TestUtils.createAccount('testAcc1', true);
        
        // Contact Records
        for(integer i=0; i<20; i++){
            Contact tempCon = new Contact();
            tempCon = TestUtils.createContact(testAcc1,'firstName'+i, 'testCon1',false);
            if(i > 10) {
            	tempCon.Salutation = 'Mrs.';
            }
            conList.add(tempCon);
        }
       	insert conList;
        
        // Set Created Date
        for(Contact con: [SELECT id, name, Salutation, rC_Bios__Gender__c
                         FROM Contact]) {
            Test.setCreatedDate(con.Id, DateTime.newInstance((dt.Year()),dt.month(),dt.day(),12, 30, 2));
        }
        
		// Gender Name Records
        for(integer i=0; i<20; i++){
          genderNameList.add(new Gender_Names__c(name='firstName'+i,IsActive__c=true));
        }
        
        insert genderNameList;
    }
}
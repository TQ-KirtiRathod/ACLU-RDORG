@isTest
public class BatchUploadGateKeeper_batchTest {
    
    public static List<BatchUploadGateKeeper_Settings__c> batchSettingList;
    public static  rC_Connect__Batch_Upload__c bup;
    public static  rC_Connect__Batch_Upload__c bup1;
    
    // Create method to verify the toZDM status
    public static testMethod void  testBatchUploadGateKeeper_batch(){
        //Create Test Data
        Account acc = TestUtils.createAccount('Test',true);
        Contact con = new Contact(AccountId=acc.id, LastName='test');
        insert con;
        batchSettingList = new List<BatchUploadGateKeeper_Settings__c>();
        createData();
        List<rC_Connect__Batch_Upload__c> buList = new List<rC_Connect__Batch_Upload__c>();
        //Create BatchUpload records
        for(Integer i=1; i<=2; i++){
	            
	        rC_Connect__Batch_Upload__c bup =TestUtils.createBatchUpload('test '+i,'test',con.Id,'test@email.com',false);
	        if(i == 0){
                bup.rC_Connect__Batch_Upload_Source_File__c = 'test';
	            bup.rC_Connect__Batch_Upload_Status__c = 'Ready for Gatekeeper';
	            bup.SB_Content_Type__c = 'donation_form';
	        }
	        if(i == 1){
	            bup.rC_Connect__Batch_Upload_Source_File__c = 'test';
                bup.rC_Connect__Batch_Upload_Status__c = 'ZDM Complete';
                bup.SB_Content_Type__c = 'Event Transaction';
	            bup.rC_Connect__Address_Country__c = 'USA';
	            bup.rC_Connect__Address_Postal_Code__c = '12345';
	            bup.rC_Connect__Address_Street_Line_1__c = 'test';
                bup.rC_Connect__Address_State__c = 'State';
	            bup.rC_Connect__Batch_Upload_Contact_1_Matched__c = con.id;
	        }
	        
	        buList.add(bup);
        }
        
        if(!buList.isEmpty()){
            insert buList;
        }
        
        Test.startTest();
        BatchUploadGateKeeper_batch obj = new BatchUploadGateKeeper_batch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        //verifying the asserConditions
        system.assertEquals('To ZDM',[SELECT Id, rC_Connect__Batch_Upload_Status__c 
                                      FROM rC_Connect__Batch_Upload__c 
                                      WHERE Name = 'test 1'][0].rC_Connect__Batch_Upload_Status__c);
        
    }
    
    
    //create the records to verify the Ready status
    public static testMethod void  testBatchUploadGateKeeper_batch1(){
        //Create test data
        Account acc = TestUtils.createAccount('Test',true);
        Contact con = new Contact(AccountId=acc.id, LastName='test');
        insert con;
        batchSettingList = new List<BatchUploadGateKeeper_Settings__c>();
        createData();
        //create batchUpload record
        rC_Connect__Batch_Upload__c bup =TestUtils.createBatchUpload('test','test',con.Id,'test@email.com',false);
        bup.rC_Connect__Batch_Upload_Source_File__c = 'test';
        bup.rC_Connect__Batch_Upload_Status__c = 'Ready for Gatekeeper';
        bup.SB_Content_Type__c = 'Advocacy Action';
        bup.rC_Connect__Batch_Upload_Source_File__c = 'Springboard';
        bup.rC_Connect__Batch_Upload_Contact_1_Matched__c = con.id;
        insert bup;
        
        Test.startTest();
        BatchUploadGateKeeper_batch obj = new BatchUploadGateKeeper_batch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        //verifying the asserConditions
        system.assertEquals('Ready',[SELECT Id, rC_Connect__Batch_Upload_Status__c FROM rC_Connect__Batch_Upload__c WHERE Name = 'test'][0].rC_Connect__Batch_Upload_Status__c);
    }
    
    
    //create the records to verify the Ready for roundData status
    public static testMethod void testBatchUploadGateKeeper_batch2(){
        
        batchSettingList = new List<BatchUploadGateKeeper_Settings__c>();
        //create Test data
        createData();
        rC_Connect__Batch_Upload__c bup =TestUtils.createBatchUpload('test 1','test',null,'test@email.com',false);
        bup.rC_Connect__Batch_Upload_Source_File__c = 'Springboard';
        bup.rC_Connect__Batch_Upload_Status__c = 'Ready for Gatekeeper';
        bup.SB_Content_Type__c = 'Event Transaction';
        insert bup;
               
        Test.startTest();
        BatchUploadGateKeeper_batch obj = new BatchUploadGateKeeper_batch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        //verifying the asserConditions
        system.assertEquals('Ready for roundData',[SELECT Id, rC_Connect__Batch_Upload_Status__c FROM rC_Connect__Batch_Upload__c WHERE Name = 'test 1'][0].rC_Connect__Batch_Upload_Status__c);
    }
    
    //create testdata to verify the another scenario for the Readyforroundata status
    public static testMethod void testBatchUploadGateKeeper_batch3(){
        batchSettingList = new List<BatchUploadGateKeeper_Settings__c>();
        //verifying the asserConditions
        createData();       
		List<rC_Connect__Batch_Upload__c> lstRCB = new List<rC_Connect__Batch_Upload__c>();
        for(Integer i=1; i<=2; i++){
            rC_Connect__Batch_Upload__c bup =TestUtils.createBatchUpload('test '+i,'test',null,'test@email.com',false);
	        bup.rC_Connect__Batch_Upload_Source_File__c = 'Committed';	        
	        bup.SB_Content_Type__c = 'springboard_petition';
	        if(i == 1){
	           bup.rC_Connect__Batch_Upload_Status__c = 'ZDM Complete';
	        }
	        if( i == 2){
	           bup.rC_Connect__Batch_Upload_Status__c = 'Ready for Gatekeeper';
	           bup.Preferences_5_Code_Value__c = '2';
	        }
	        lstRCB.add(bup);
        }
        
        Test.startTest();
        insert lstRCB;
        BatchUploadGateKeeper_batch obj = new BatchUploadGateKeeper_batch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        //verifying the asserConditions
        system.assertEquals('Ready for roundData',[SELECT Id, rC_Connect__Batch_Upload_Status__c FROM rC_Connect__Batch_Upload__c WHERE Name = 'test 1'][0].rC_Connect__Batch_Upload_Status__c);
    }
    
    //create TestData
    public static void createData(){
        
        BatchUploadGateKeeper_Settings__c bugs = new BatchUploadGateKeeper_Settings__c();
        bugs.name = 'Default';
        bugs.Max_Number_of_P4s__c = 100001;
        bugs.Max_Number_Through__c = 1.5;
        batchSettingList.add(bugs);
        
        insert batchSettingList;
    }
    
    
    //test method for BatchUploadGateKeeperbatch_Schedule 
    public static testMethod void testschedule() 
    {
        batchSettingList = new List<BatchUploadGateKeeper_Settings__c>();
        createData();
        rC_Connect__Batch_Upload__c bup = new rC_Connect__Batch_Upload__c();
        bup.Name = 'test 1';
        bup.rC_Connect__Batch_Upload_Source_File__c = 'test';
        bup.rC_Connect__Batch_Upload_Status__c = 'Ready for Gatekeeper';
        bup.SB_User_Id__c='10371';
        insert bup;
        
        Test.StartTest();
        BatchUploadGateKeeperbatch_Schedule sh1 = new BatchUploadGateKeeperbatch_Schedule();
        String sch = '0 0 23 * * ?'; 
        String jobId = system.schedule('test my BatchUploadGateKeeperbatch_Schedule', sch, sh1); 
        Test.stopTest(); 
        system.assert(jobId != null);
    }
}
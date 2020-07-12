/** Organization :: roundCorner Inc.
  * @Class Name: BUP_DeleteEventsSchedulableTest
  * @Description: This test class is used to validate BUP_DeleteEventsBatchable functionality.
  **/
@isTest
private class BUP_CustomDeleteEventsSchedulableTest {
     
    /**
     * @Description: Used to check if rC_Connect__Batch_Upload record has batch upload status picklist value
     *               is Flagged then related child record is deleted.
     * @Param: NA
     * @Return: NA
     **/
     static testMethod void checkBatchForBatchUploadStatusFlagged() {
        List<rC_Connect__Batch_Upload__c>  batchUploadList = new List<rC_Connect__Batch_Upload__c>();
        List<rC_BUP__Event__c> eventList = new List<rC_BUP__Event__c>();
        
        BUP_CustomDeleteEventSchedulableData testDataService = new BUP_CustomDeleteEventSchedulableData();
        // Create rC_Connect__Batch_Upload records with batch upload status picklist value Flagged.
        batchUploadList = testDataService.createBatchUploadRecord( 5, 'New' );
        // Insert rC_Connect__Batch_Upload records.
        database.insert( batchUploadList, false );
        
         for(rC_Connect__Batch_Upload__c bu: batchUploadList){
            bu.rC_Connect__Batch_Upload_Status__c = 'Flagged';
        }   
        
        database.update(batchUploadList);
        // create batch upload framework settings
        testDataService.createBatchUploadFrameworkSettings();
        
        batchUploadList.clear();
        batchUploadList = [ SELECT Id, 
                                   rC_Connect__Batch_Upload_Status__c 
                            FROM rC_Connect__Batch_Upload__c
                            LIMIT 50000 ];
        
        system.assertNotEquals( null, batchUploadList );
        system.assertEquals( 5, batchUploadList.size() );
        
        // Check rC_Connect__Batch_Upload record is inserted.
        for( integer count = 0; count < 5 ; count++ ) {
            
            system.assertNotEquals( null, batchUploadList[ count ].Id );
            system.assertEquals( 'Flagged', batchUploadList[ count ].rC_Connect__Batch_Upload_Status__c );  
        }
        // Create Event records.
        eventList = testDataService.createEventRecord( 5, batchUploadList[ 0 ].Id,'Processed');
        // Insert Event records.
        database.insert( eventList, false );
        
        eventList.clear();
        eventList = [ SELECT Id, 
                             rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c
                      FROM rC_BUP__Event__c 
                      LIMIT 50000 ];
        
        system.assertNotEquals( null, eventList );
        system.assertEquals( 5, eventList.size() );
        
        // Check Event record is inserted.
        for( integer count = 0; count < 5 ; count++ ) {
            
            system.assertNotEquals( null, eventList[ count ].Id );
            system.assertEquals( batchUploadList[ 0 ].Id , eventList[ count ].rC_BUP__Batch_Upload__c );    
        }
        
        // Execute BUP_CustomDeleteEventsBatchable batch.
        test.startTest();
            new BUP_CustomDeleteEventSchedulable().execute(null);
        test.stopTest();
        
        eventList.clear();
        eventList = [ SELECT Id, 
                             rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c
                      FROM rC_BUP__Event__c 
                      LIMIT 50000 ];
        // Check Event record is deleted after batch execute if rC_Connect__Batch_Upload record has batch upload status picklist value
        //  is Flagged.           
        system.assertNotEquals( null, eventList, 'checkBatchForBatchUploadStatusFlagged() :: Events are not created.' );
        system.assertEquals( 5, eventList.size() , 'checkBatchForBatchUploadStatusFlagged() :: Events records mismatch.');
    }
    
    /**
     * @Description: Used to check if rC_Connect__Batch_Upload record has batch upload status picklist value
     *               is Processed then related child record is deleted.
     * @Param: NA
     * @Return: NA
     **/
    static testMethod void checkBatchForBatchUploadStatusProcessed() {
        List<rC_Connect__Batch_Upload__c>  batchUploadList = new List<rC_Connect__Batch_Upload__c>();
        List<rC_BUP__Event__c> eventList = new List<rC_BUP__Event__c>();
        BUP_CustomDeleteEventSchedulableData testDataService = new BUP_CustomDeleteEventSchedulableData();
       
        // Create rC_Connect__Batch_Upload records with batch upload status picklist value Processed.
        batchUploadList = testDataService.createBatchUploadRecord( 1,'New');
        // Insert rC_Connect__Batch_Upload records.
        database.insert( batchUploadList, false );

        for(rC_Connect__Batch_Upload__c bu: batchUploadList){
            bu.rC_Connect__Batch_Upload_Status__c = 'Committed';
        }   
        
        database.update(batchUploadList);
        
        // create batch upload fraework settings
        testDataService.createBatchUploadFrameworkSettings();
       
        batchUploadList.clear();
        batchUploadList = [ SELECT Id, 
                                   rC_Connect__Batch_Upload_Status__c 
                            FROM rC_Connect__Batch_Upload__c
                            LIMIT 50000 ];
       
        for(rC_Connect__Batch_Upload__c bu: batchUploadList){
            bu.rC_Connect__Batch_Upload_Status__c = 'Committed';
        }   
        
        database.update(batchUploadList);
        // Create Event records.
        eventList = testDataService.createEventRecord( 5, batchUploadList[ 0 ].Id,'Processed');
        // Insert Event records.
        database.insert( eventList, false );
        eventList.clear();
        eventList = [ SELECT Id, 
                            rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c
                      FROM rC_BUP__Event__c 
                      LIMIT 50000 ];
        
        // Execute BUP_DeleteEventsBatchable batch.
        test.startTest();
         new BUP_CustomDeleteEventSchedulable().execute(null);
        test.stopTest();
        
        eventList.clear();
        eventList = [ SELECT Id, 
                            rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c
                      FROM rC_BUP__Event__c 
                      LIMIT 50000 ];
        // Check Event record is deleted after batch execute if rC_Connect__Batch_Upload record has batch upload status picklist value
        //  is Processed.             
        system.assertEquals( 0, eventList.size(), 'checkBatchForBatchUploadStatusProcessed() :: Events are not deleted as they can be into different states' );
    }
}
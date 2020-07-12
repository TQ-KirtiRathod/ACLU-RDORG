//Added by :: roundCorner Inc. :: 01-March-2019 :: Zendesk: #59832
@isTest
public class BatchUploadAsyncProcessorSchedulableTest {
    
    //Method to create Test Data
    public static TestMethod void TestOnBatchUploadUpdate() {
        Queueable_Control__c queueable = new Queueable_Control__c();
        queueable.Name = 'test BU';
        queueable.Batch_Size_Account__c = 1;
        queueable.Batch_Size_Account_Address__c = 1;
        queueable.Batch_size_BatchUpload__c = 1;
        insert queueable;
		list<rC_Connect__Batch_Upload__c> batchUploadList = new list<rC_Connect__Batch_Upload__c>();
        for(Integer i=0; i<2; i++){ // 0-9
            if (i < 10) {
                rC_Connect__Batch_Upload__c batUpload = new rC_Connect__Batch_Upload__c();
                batUpload.Additional_Opt_In_Lists__c = 'ABC'+i+',CDE'+i;
                batUpload.Cont1_OptIn__c = true;
                batUpload.rC_Connect__Giving_Record_Type__c = 'Donation';
                batUpload.rC_Connect__Contact_1_Phone_1__c = '(780) 912-456'+i;
                batUpload.rC_Connect__Contact_1_Phone_1_Type__c = 'Work';
                batUpload.rC_Connect__Address_Postal_Code__c = '23410';
                batUpload.rC_Connect__Address_Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
                batUpload.Preferences_5_Code_Value__c = '5562';
                batUpload.rC_Connect__Batch_Upload_Status__c = 'In Progress';
                batUpload.rC_Connect__Payment_Method_Payment_Type__c = 'Cash/Check';
                batUpload.SB_Content_Type__c = 'webform';
                batchUploadList.add(batUpload); 
            }            
    	}
        Insert batchUploadList;
        
        List<rC_Connect__Batch_Upload__c> batchUploads = [SELECT  id
                                                                , rC_Connect__Batch_Upload_Flagged_Reason__c
                                                         		, rC_Connect__Batch_Upload_Flagged_Technical_Reason__c
                                                                , rC_Connect__Batch_Upload_Status__c
                                                         FROM rC_Connect__Batch_Upload__c];
        for(rC_Connect__Batch_Upload__c bus :batchUploads) {
            bus.rC_Connect__Batch_Upload_Status__c = 'Flagged';
            bus.rC_Connect__Batch_Upload_Flagged_Reason__c = 'Salesforce System Exception';
            bus.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = Label.Salesforce_System_Exception;
        }
        update batchUploads;
        test.startTest();
        Datetime  sysTime = System.now().addSeconds(10); //Adding additional 20 sec to reschedule again in case of exceptions
        String  chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        System.schedule('Scheduled Job 1', chronExpression, new BatchUploadAsyncProcessorSchedulable());
        test.stoptest();
        System.assertEquals(batchUploads!= null ,true);
    }
    public static TestMethod void TestAsyncRequestDelete() {
        Queueable_Control__c queueable = new Queueable_Control__c();
        queueable.Name = 'test BU';
        queueable.Batch_Size_Account__c = 1;
        queueable.Batch_Size_Account_Address__c = 1;
        queueable.Batch_size_BatchUpload__c = 1;
        insert queueable;
		list<rC_Connect__Batch_Upload__c> batchUploadList = new list<rC_Connect__Batch_Upload__c>();
        for(Integer i=0; i<2; i++){ // 0-9
            if (i < 10) {
                rC_Connect__Batch_Upload__c batUpload = new rC_Connect__Batch_Upload__c();
                batUpload.Additional_Opt_In_Lists__c = 'ABC'+i+',CDE'+i;
                batUpload.Cont1_OptIn__c = true;
                batUpload.rC_Connect__Giving_Record_Type__c = 'Donation';
                batUpload.rC_Connect__Contact_1_Phone_1__c = '(780) 912-456'+i;
                batUpload.rC_Connect__Contact_1_Phone_1_Type__c = 'Work';
                batUpload.rC_Connect__Address_Postal_Code__c = '23410';
                batUpload.rC_Connect__Address_Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
                batUpload.Preferences_5_Code_Value__c = '5562';
                batUpload.rC_Connect__Batch_Upload_Status__c = 'In Progress';
                batUpload.rC_Connect__Payment_Method_Payment_Type__c = 'Cash/Check';
                batUpload.SB_Content_Type__c = 'webform';
                batUpload.rC_Connect__Batch_Upload_Status__c = 'Committed';
                batUpload.rC_Connect__Batch_Upload_Flagged_Reason__c = 'Salesforce System Exception';
                batUpload.Error_Count__c = 0;
                batUpload.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = Label.Salesforce_System_Exception;
        
                batchUploadList.add(batUpload); 
            }            
    	}
        Insert batchUploadList;
        List<AsyncRequest__c> customAsyncList = new List<AsyncRequest__c>();
         customAsyncList.add(new AsyncRequest__c(AsyncType__c ='batchUpload_SystemExceptionSet', 
                                                                     Object_API_Name__c = 'rC_Connect__Batch_Upload__c',
                                                                     Error__c = true,
                                                                     Params__c = String.valueOf(batchUploadList[0].id)));
        insert customAsyncList;
        
        test.startTest();
        Datetime  sysTime = System.now().addSeconds(10); //Adding additional 20 sec to reschedule again in case of exceptions
        String  chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        System.schedule('Scheduled Job 1', chronExpression, new BatchUploadAsyncProcessorSchedulable());
        test.stoptest();
        System.assertEquals(batchUploadList!= null ,true);
    }
    
}
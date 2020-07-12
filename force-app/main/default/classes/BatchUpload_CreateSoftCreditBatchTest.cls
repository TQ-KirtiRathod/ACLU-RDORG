@isTest
public class BatchUpload_CreateSoftCreditBatchTest {
	public static list<Contact> contactList;
    public static List<rC_Connect__Batch_Upload__c> batchUploadList;
    
    //Method to create Test Data
    public static void createTestData() {
        contactList = new list<Contact>();
        batchUploadList = new list<rC_Connect__Batch_Upload__c>();
        
        for(Integer i=0;i<15;i++) {
            Contact con = TestUtils.createContact(null,'cons'+i,'TestConBatch'+i,false);
            contactList.add(con);
        }
        insert contactList;
        
        Email_Preference_List__c pref1 = new Email_Preference_List__c(Affiliation__c = 'AK', Exclude_from_Preference_Center__c = false, Is_Home_Affiliate_List__c = true, List_Code__c = 'AK', List_Label__c ='ACLU Action National', Name = 'ACLU Action National');
        Email_Preference_List__c pref2 = new Email_Preference_List__c(Affiliation__c = 'CN', Exclude_from_Preference_Center__c = true, Is_Home_Affiliate_List__c =true , List_Code__c = 'ca', List_Label__c ='ACLU of California', Name = 'ACLU of California');
        Email_Preference_List__c pref3 = new Email_Preference_List__c(Affiliation__c ='ME' , Exclude_from_Preference_Center__c =false , Is_Home_Affiliate_List__c =true , List_Code__c ='ME' , List_Label__c = 'ACLU of Maine', Name = 'ACLU of Maine');
        List<Email_Preference_List__c> prefToInsert = new List<Email_Preference_List__c>{pref1, pref2,pref3};
        insert prefToInsert;
        Zip_Affiliate__c za1 = TestUtils.createZipAffiliate('23410',false);
        za1.Affiliation__c = '1234';
        Zip_Affiliate__c za2 = TestUtils.createZipAffiliate('23412',false);
        za2.Affiliation__c = '1234';
        Zip_Affiliate__c za3 = TestUtils.createZipAffiliate('123456',false);
        za3.Affiliation__c = '1234';
        List<Zip_Affiliate__c> zaList = new List<Zip_Affiliate__c>{za1, za2,za3};
        insert zaList;
        for(Integer i=0; i<15; i++){ // 0-9
            if (i < 10) {
                rC_Connect__Batch_Upload__c batUpload = TestUtils.createBatchUpload('TESTBATCH'+i,'TESTING'
                                                      +i,contactList[i].Id,'Test'+i+'@ymail.com',false);
                batUpload.Additional_Opt_In_Lists__c = 'ABC'+i+',CDE'+i;
                batUpload.Cont1_OptIn__c = true;
                batUpload.rC_Connect__Giving_Record_Type__c = 'Donation';
                batUpload.rC_Connect__Contact_1_Phone_1__c = '(780) 912-456'+i;
                batUpload.rC_Connect__Contact_1_Phone_1_Type__c = 'Work';
                batUpload.rC_Connect__Address_Postal_Code__c = '23410';
                batUpload.rC_Connect__Address_Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
                batUpload.Preferences_5_Code_Value__c = '5562';
                batUpload.rC_Connect__Batch_Upload_Status__c = 'Committed';
                batUpload.rC_Connect__Payment_Method_Payment_Type__c = 'Cash/Check';
                batUpload.SB_Content_Type__c = 'webform';
                batUpload.isSoft_Credit__c = true;
                batchUploadList.add(batUpload); 
            }
            if (i>10 && i<13) {
                rC_Connect__Batch_Upload__c batchUpload = TestUtils.createBatchUpload('TESTBATCH'+i,'TESTING'
                                                        +i,contactList[i].Id,'Test'+i+'@ymail.com',false);
                batchUpload.Additional_Opt_In_Lists__c = 'ABC'+i+',CDE'+i;
                batchUpload.Cont1_OptIn__c = false;
                batchUpload.rC_Connect__Giving_Record_Type__c = 'Donation';
                batchUpload.rC_Connect__Contact_1_Phone_1__c = '(799) 912-456'+i;
                batchUpload.rC_Connect__Contact_1_Phone_1_Type__c = 'Work';
                batchUpload.rC_Connect__Batch_Upload_Status__c = 'Processed';
                batchUpload.rC_Connect__Address_Postal_Code__c = '23412';
                batchUpload.rC_Connect__Address_Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
                batchUpload.rC_Connect__Batch_Upload_Contact_1_Matched__c = contactList[i-5].Id;
                batchUpload.Cont1_Email__c = 'Test@example.com';
                batchUpload.rC_Connect__Batch_Upload_Account_Matched__c = TestUtils.createAccount('Account'+i,true).Id;
                batchUpload.Preferences_5_Code_Value__c = '672';
                batchUpload.rC_Connect__Payment_Method_Payment_Type__c = 'Paypal';
                batchUpload.SB_Content_Type__c = 'webform';
                batchUpload.isSoft_Credit__c = true;
                batchUploadList.add(batchUpload); 
            }
            if (i>12 && i<15) {
                rC_Connect__Batch_Upload__c batchUpload = TestUtils.createBatchUpload('TESTBATCH'+i,'TESTING'+i,null,'',false);
                batchUpload.Name = 'Contact Test Batch';
                batchUpload.rC_Connect__Batch_Upload_Status__c = 'New';
                batchUpload.rC_Connect__Batch_Upload_Source_File__c = 'Springboard';
                batchUpload.rC_Connect__Exclude_Giving__c = true;
                batchUpload.Cont1_Email__c = 'Test@example.com';
                batchUpload.Cont1_OptIn__c = true;
                batchUpload.SB_Form_Affiliation__c = 'NAT';
                batchUpload.SB_Acquisition_Upload_source__c = 'Test';
                batchUpload.rC_Connect__Payment_Method_Payment_Type__c = 'Paypal';
                batchUpload.rC_Connect__Address_Postal_Code__c = '23410';
                batchUpload.rC_Connect__Address_Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
                batchUpload.isSoft_Credit__c = true;
                batchUploadList.add(batchUpload); 
            }
        }
    }

    public static testMethod void TestInsertUpdateScenarios(){
        createTestData();
        Batch_Log__c b = TestUtils.createBatchLog('Test' , true);
        
        //insert batchUploadList;
        batchUploadList[11].rC_Connect__Address_Country__c = 'US';
        batchUploadList[11].rC_Connect__Address_Postal_Code__c = '123456';
        batchUploadList[11].rC_Connect__Address_Street_Line_1__c='Stree line 1';
        batchUploadList[11].rC_Connect__Batch_Upload_Status__c = 'To ZDM';
        batchUploadList[9].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[9].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c='No Remaining transactions to fulfill';
        batchUploadList[9].Preferences_4_Code_Value__c='5562';
        insert batchUploadList;
        batchUploadList[9].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[9].Batch_Log__c = b.Id;
        batchUploadList[10].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[10].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c='No Remaining transactions to fulfill';
        batchUploadList[11].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[11].rC_Connect__Batch_Upload_Status__c = 'To ZDM';
        update batchUploadList;
        batchUploadList[10].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[10].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c= System.Label.Batch_Upload_Flagged_Reason_For_SB_User_ID 
                                                                                + System.Label.Batch_Upload_Flagged_Reason_BUP_CommitDomain;
        batchUploadList[11].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[11].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = System.Label.Insufficient_access_rights_on 
                                                                                 + System.Label.Unable_to_obtain_exclusive_access + ' 003';
        batchUploadList[11].kwrc__KW_Error_Code__c = 'Test';
        update batchUploadList;
        
        rC_BUP__Event__c transactionEvent = new rC_BUP__Event__c();
        transactionEvent.rC_BUP__Batch_Upload__c = batchUploadList[9].Id;
        transactionEvent.rC_BUP__Topic_Sequence__c = 7;
        transactionEvent.rC_BUP__Topic_Name__c = 'Transaction_Topic'; 
        transactionEvent.rC_BUP__Event_State__c = 'Suspend';
        insert transactionEvent;
        
        rC_BUP__Queue__c transactionQueue = new rC_BUP__Queue__c();
        transactionQueue.rC_BUP__Process_Name__c = 'Transaction_Process';
        transactionQueue.rC_BUP__Queue_State__c = 'Suspend';
        transactionQueue.rC_BUP__Process_Sequence__c = 1;
        transactionQueue.rC_BUP__Event__c = transactionEvent.Id;
        insert transactionQueue;

        rC_BUP__Event__c batchUploadTopicEvent = new rC_BUP__Event__c();
        batchUploadTopicEvent.rC_BUP__Batch_Upload__c = batchUploadList[9].Id;
        batchUploadTopicEvent.rC_BUP__Topic_Sequence__c = 14;
        batchUploadTopicEvent.rC_BUP__Topic_Name__c = 'BatchUpload_Topic'; 
        batchUploadTopicEvent.rC_BUP__Event_State__c = 'Processed';
        insert batchUploadTopicEvent;

        rC_BUP__Queue__c batchUploadQueue = new rC_BUP__Queue__c();
        batchUploadQueue.rC_BUP__Process_Name__c = 'Batch_Upload_Process';
        batchUploadQueue.rC_BUP__Queue_State__c = 'Processed';
        batchUploadQueue.rC_BUP__Process_Sequence__c = 1;
        batchUploadQueue.rC_BUP__Event__c = batchUploadTopicEvent.Id;
        insert batchUploadQueue;

		Test.startTest();
			new BatchUpload_CreateSoftCreditScheduler().execute(null);
        Test.stopTest();
        
        system.assertEquals('In Progress', [SELECT Id
                                                 , rC_Connect__Batch_Upload_Status__c
                                              FROM rC_Connect__Batch_Upload__c 
                                             WHERE Id = :batchUploadList[9].Id
                                           ].rC_Connect__Batch_Upload_Status__c, ' Failed to update.');
        
        System.assertEquals('Complete', [SELECT Id
                                              , rC_BUP__Queue_State__c
                                           FROM rC_BUP__Queue__c
                                          WHERE Id = :transactionQueue.Id].rC_BUP__Queue_State__c, ' Failed to update queue.');
    }
    
}
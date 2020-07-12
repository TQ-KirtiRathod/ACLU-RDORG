/* 
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 28, 2016
*Purpose : Test Coverage for BatchUploadHandler
*/
@isTest 
public with sharing class BatchUploadHandlerTest {
    public static list<Contact> contactList;
    public static List<rC_Connect__Batch_Upload__c> batchUploadList;
    public static Id pledgeOppPaymentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    public static Id donationOppPaymentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    
    //Testing if Email and Email Preference are created and Email is updated, if there is any updation on Batch Upload also, 
    //Testing on Phone creation.
    public static TestMethod void TestOnEmailPhoneCreation(){
        createTestData();
        Email__c em = TestUtils.createEmail(contactList[0].Id, 'test1234@example.com',false);
        insert em;
        batchUploadList[0].Cont1_Email__c = 'test1234@example.com';
        Test.startTest();
        insert batchUploadList;
        
        // Verifying Email Record Insertion 
        for(Email__c emalRecord : [SELECT Id, Opt_In__c, External_Id__c FROM Email__c 
                                   WHERE External_Id__c =: String.valueOf(batchUploadList[10].rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)
                                   +'_'+batchUploadList[10].Cont1_Email__c]) {
            System.assertEquals(emalRecord.Opt_In__c,batchUploadList[10].Cont1_OptIn__c);  
        }
        
        // Verifying Phone Record Insertion 
        for(Phone__c phoneRecord : [SELECT Id, Phone_Type__c FROM Phone__c 
                                    WHERE External_Id__c =: String.valueOf(batchUploadList[10].rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)
                                    +'_'+batchUploadList[10].rC_Connect__Contact_1_Phone_1__c]) {
            System.assertEquals(phoneRecord.Phone_Type__c, batchUploadList[10].rC_Connect__Contact_1_Phone_1_Type__c);  
        }
        
        // Verifying Preference Code functionality
        batchUploadList[11].Preferences_5_Code_Value__c = '113327';
        batchUploadList[11].rC_Connect__Batch_Upload_Contact_1_Matched__c = contactList[2].Id;
        batchUploadList[11].rC_Connect__Batch_Upload_Status__c = 'Committed';
        batchUploadList[11].rC_Connect__Address_Postal_Code__c = '123456';
        update batchUploadList[11];
        
        
        rC_Connect__Batch_Upload__c bu = [SELECT Id,Cont1_OptIn__c,SB_Acquisition_Initial_market_source__c,
                                            SB_Acquisition_Device_Name__c,rC_Connect__Contact_1_Donor_ID__c,Cont1_Email__c,
                                            rC_Connect__Batch_Upload_Contact_1_Matched__c ,Additional_Opt_In_Lists__c,
                                            rC_Connect__Address_Postal_Code__c
                                          FROM rC_Connect__Batch_Upload__c
                                          WHERE Id =: batchUploadList[3].Id];
        
        bu.rC_Connect__Batch_Upload_Contact_1_Matched__c = contactList[0].Id;
        bu.Cont1_Email__c = 'Test11@ymail.com';
        bu.Cont1_OptIn__c = false;
        update bu;
        
        Email__c em1 = [SELECT Id,Opt_In__c,External_Id__c FROM Email__c 
                        WHERE External_Id__c =: String.valueOf(bu.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+bu.Cont1_Email__c];
        System.assertEquals(em1.Opt_In__c,bu.Cont1_OptIn__c);  
        
        Test.stopTest();
        String externalId = String.valueOf(bu.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + bu.Cont1_Email__c;
        map<Email__c, String> mapEmailPref = new Map<Email__c, String>();
        Email__c mail = new Email__c();
        mail = [Select id, Opt_In__c, Contact__c, Email_address__c FROM Email__c
                                        where Contact__c =: bu.rC_Connect__Batch_Upload_Contact_1_Matched__c 
                                        AND Email_address__c =: bu.Cont1_Email__c LIMIT 1];
        mapEmailPref.put(mail, bu.Additional_Opt_In_Lists__c);  
        map<String, rC_Connect__Batch_Upload__c> mapBatches = new Map<String, rC_Connect__Batch_Upload__c>();
        mapBatches.put(externalId, bu);
        BatchUploadConstituentUpdater.createEmailPrefrences( mapEmailPref, false, mapBatches, false);
    }
    
    
    //Method for Testing Address Source population functionality
    public static TestMethod void TestAddressSourceDefaulting() {
        Set<String> sourceSet = new Set<String>{'springboard_petition', 'sba_message_action', 'sba_social_action', 
            'webform', 'volunteer_form', 'signup_form'};
                createTestData();
        Test.startTest();
        insert batchUploadList;
        
        for(rC_Connect__Batch_Upload__c objUpload : [SELECT Id, Address_Source__c, SB_Content_Type__c 
                                                     FROM rC_Connect__Batch_Upload__c 
                                                     WHERE Id IN: batchUploadList]) {
            if(sourceSet.contains(objUpload.SB_Content_Type__c)) {
                System.assertEquals('Advocacy', objUpload.Address_Source__c);
            } else {
                System.assertEquals(null, objUpload.Address_Source__c);
            }
        }
        Test.stopTest();
    }
    
    //Method for Testing Giving Paid Checkbox functionality
    public static TestMethod void TestGivingPaidtrue() {
        List<rC_Connect__Batch_Upload__c> batchUploadToUpdate = new List<rC_Connect__Batch_Upload__c>();
        
        createTestData();
        Test.startTest();
        insert batchUploadList;
        
        // Verifying Positive and Negative Scenarios on Insert 
        for(rC_Connect__Batch_Upload__c objUpload : [SELECT Id, rC_Connect__Payment_Method_Payment_Type__c, rC_Connect__Giving_Paid__c 
                                                     FROM rC_Connect__Batch_Upload__c WHERE Id IN: batchUploadList]) {
            if(objUpload.rC_Connect__Payment_Method_Payment_Type__c == 'Cash/Check') {
                System.assertEquals(true, objUpload.rC_Connect__Giving_Paid__c);
            } else {
                System.assertEquals(false, objUpload.rC_Connect__Giving_Paid__c);
                objUpload.rC_Connect__Payment_Method_Payment_Type__c = 'Cash/Check';
                batchUploadToUpdate.add(objUpload);
            }
        }
        
        if(batchUploadToUpdate.size() > 0) {
            update batchUploadToUpdate;
        }
        
        // Verifying Update Scenarios
        for(rC_Connect__Batch_Upload__c objUpload : [SELECT Id, rC_Connect__Giving_Paid__c FROM rC_Connect__Batch_Upload__c 
                                                     WHERE Id IN: batchUploadToUpdate]) {
            System.assertEquals(true, objUpload.rC_Connect__Giving_Paid__c);
        }
        Test.stopTest();
    }
    
    //Method for Testing Contact First name and Last Name Defaulting
    public static TestMethod void TestContactNameDefaulting() {
        createTestData();
        batchUploadList[13].rC_Connect__Contact_1_Last_Name__c = 'Unknown';
        Test.startTest();
        insert batchUploadList;
        
        // Verifying Contact Last Name Default Setting functionality
        for(rC_Connect__Batch_Upload__c objUpload : [SELECT Id, rC_Connect__Batch_Upload_Contact_1_Matched__c, 
                                                       rC_Connect__Contact_1_First_Name__c, rC_Connect__Contact_1_Last_Name__c 
                                                     FROM rC_Connect__Batch_Upload__c WHERE Id IN: batchUploadList]) {
            // Positive Scenarios
            if(String.isBlank(objUpload.rC_Connect__Batch_Upload_Contact_1_Matched__c)) {
                System.assertEquals(Label.Default_Contact_First_Name, objUpload.rC_Connect__Contact_1_First_Name__c);
                System.assertEquals(Label.Default_Contact_Last_Name, objUpload.rC_Connect__Contact_1_Last_Name__c);
            } else {
                // Negative Scenarios
                System.assertNotEquals(Label.Default_Contact_First_Name, objUpload.rC_Connect__Contact_1_First_Name__c);
                System.assertNotEquals(Label.Default_Contact_Last_Name, objUpload.rC_Connect__Contact_1_Last_Name__c);
            }
        }
        Test.stopTest();
    }
    
    //Method for Testing cloneBatchUploadHardCredits and updateSoftCreditBatchUploads methods from Handler Class.
    public static TestMethod void TestSoftCreditsBatchUploads() {
        createTestData();
        batchUploadList[7].rC_Connect__Batch_Upload_Status__c = 'Ready';
        batchUploadList[7].Has_Soft_Credit__c = true;
        batchUploadList[7].Batch_Upload_Reference_ID__c = '';
        Test.startTest();
        
        insert batchUploadList;
        
        // Verify that a record has been cloned and reference id is getting populated on hard credit batch upload record
        for(rC_Connect__Batch_Upload__c buObj : [SELECT Id, Batch_Upload_Reference_ID__c, rC_Connect__Batch_Upload_Parent_Giving_Matched__c 
                                                 FROM rC_Connect__Batch_Upload__c WHERE Id =: batchUploadList[7].Id]) {
            System.assertEquals(true, buObj.Batch_Upload_Reference_ID__c != null);
        }
        
        // Create Opportunity Test Record
        Opportunity opp = TestUtils.createOpportunity(batchUploadList[11].rC_Connect__Batch_Upload_Account_Matched__c, 'TestOpp', true);
        Opportunity oppChild = TestUtils.createOpportunity(batchUploadList[11].rC_Connect__Batch_Upload_Account_Matched__c, 'TestOppChild', false);
        oppChild.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        oppChild.CloseDate = System.today();
        oppChild.rC_Giving__Parent__c = opp.Id;
        insert oppChild;
        
        
        batchUploadList[7].rC_Connect__Batch_Upload_Status__c = 'Committed';
        batchUploadList[7].rC_Connect__Batch_Upload_Giving_Matched__c = opp.Id;
        batchUploadList[7].rC_Connect__Batch_Upload_Parent_Giving_Matched__c = opp.Id;
        String transId = String.valueOf(oppChild.Id).substring(0, 15);
        batchUploadList[7].Related_Transaction__c = transId;
        update batchUploadList;
        
        // Verify that a record has been cloned and reference id is getting populated on hard credit batch upload record
        for(rC_Connect__Batch_Upload__c buObj : [SELECT Id, Batch_Upload_Reference_ID__c FROM rC_Connect__Batch_Upload__c 
                                                 WHERE Id =: batchUploadList[7].Batch_Upload_Reference_ID__c]) {
            System.assertEquals(batchUploadList[7].rC_Connect__Batch_Upload_Parent_Giving_Matched__c, buObj.rC_Connect__Batch_Upload_Parent_Giving_Matched__c);
        }
        Test.stopTest();
    }
    
    public static TestMethod void TestInsertUpdateScenarios(){
        createTestData();
        Batch_Log__c b = TestUtils.createBatchLog('Test' , true);
        Test.startTest();
        
        //insert batchUploadList;
        batchUploadList[11].rC_Connect__Address_Country__c = 'US';
        batchUploadList[11].rC_Connect__Address_Postal_Code__c = '123456';
        batchUploadList[11].rC_Connect__Address_Street_Line_1__c='Stree line 1';
        batchUploadList[11].rC_Connect__Batch_Upload_Status__c = 'To ZDM';
        batchUploadList[9].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[9].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c='duplicate value found: BUP_CommitDomain duplicates value on record with id:';
        batchUploadList[9].Preferences_4_Code_Value__c='5562';
        insert batchUploadList;
        batchUploadList[9].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[9].Batch_Log__c = b.Id;
        batchUploadList[10].rC_Connect__Batch_Upload_Status__c = 'Flagged';
        batchUploadList[10].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c='duplicate value found: BUP_CommitDomain duplicates value on record with id:';
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
        rC_Connect__Batch_Upload__c bu = [SELECT Id,Cont1_OptIn__c,SB_Acquisition_Initial_market_source__c,
                                            SB_Acquisition_Device_Name__c,rC_Connect__Contact_1_Donor_ID__c,Cont1_Email__c,
                                            rC_Connect__Batch_Upload_Contact_1_Matched__c 
                                          FROM rC_Connect__Batch_Upload__c
                                          WHERE Id =: batchUploadList[3].Id];
        
        bu.rC_Connect__Batch_Upload_Contact_1_Matched__c = contactList[4].Id;
        bu.Cont1_Email__c = 'Test11@ymail.com';
        bu.Cont1_OptIn__c = false;
        update bu;
        
        Email__c em1 = [SELECT Id,Opt_In__c,External_Id__c FROM Email__c WHERE External_Id__c =: String.valueOf(bu.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+bu.Cont1_Email__c];
        System.assertEquals(em1.Opt_In__c,bu.Cont1_OptIn__c);  
        Test.stopTest();
    }
    
    //Method to create bathUplaod Share records based on the createdUser (Testing createShareRecords method from handler class)
    public static TestMethod void TestShareRecrodsCreated(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.runas(thisUser) {
            setupTestData();
        }
        
        User testUser = [SELECT Id FROM User WHERE UserName = 'test.random1.user@aclu.org.randomUser'];
        
        Test.startTest();
        System.runas(TestUser){
            if(!batchUploadList.IsEmpty()){
                batchUploadList[0].rC_Connect__Batch_Upload_Status__c='Committed';
                batchUploadList[0].rC_Connect__Batch_Upload_Account_Matched__c = TestUtils.createAccount('Account',true).Id;
                batchUploadList[0].Preferences_5_Code_Value__c='5562';
                batchUploadList[0].rC_Connect__Contact_1_Phone_1__c='(780) 912-4561';
                insert batchUploadList;
            }
        }
        Test.StopTest();
        
        List<Group> groupList = [SELECT Id FROM Group];
        System.assertEquals(4, [SELECT Id 
                                FROM rC_Connect__Batch_Upload__share 
                                WHERE parentId IN :batchUploadList 
                                AND UserOrGroupId IN :groupList 
                                AND AccessLevel = 'Edit'].size());
    }
    
    //Method for Creating Test data for TestShareRecrodsCreated method
    public static void setupTestData() {
        contactList = new List<Contact>();
        batchUploadList = new List<rC_Connect__Batch_Upload__c>();
        List<Account> accountList = new List<Account>();
        List<Group> groupList = new List<Group>();
        List<GroupMember> groupMemberList = new List<GroupMember>();
        List<Email__c> emailList = new List<Email__c>();
        List<Phone__c> phoneList = new List<Phone__c>();
        
        //Create group and group member
        groupmember objgroupmember = new groupmember();
        
        User testUser = TestUtils.createUser('User1','test.random1.user@aclu.org.randomUser',UserInfo.getUserRoleId(),true);
        groupList.add(TestUtils.createGroup('UK',false));
        groupList.add(TestUtils.createGroup('Spain',false));
        insert groupList;
        groupMemberList.add(TestUtils.createGroupmember(testUser.Id, groupList[0].Id, false));
        groupMemberList.add(TestUtils.createGroupmember(testUser.Id, groupList[1].Id, false));
        insert groupMemberList;
        
        Queueable_Control__c queControl = TestUtils.createQueueableControl('MainQueueable', 100, 100, false);
        queControl.Batch_Size_Phone__c=100;
        queControl.Queueable_Enabled__c=true;
        queControl.Batch_Size_Account_Address__c = 0121;
        insert queControl;
        
        // Account Records
        for(Integer i=0; i<2; i++){   
            Account acc = TestUtils.createAccount('Account'+i, false);
            accountList.add(acc);
        }
        insert accountList;
        
        // Contact creation
        for(Account acc: accountList) {
            Contact con = TestUtils.createContact( acc, 'firstName', 'lastName', false);
            contactList.add(con);
        }
        insert contactList;
        
        // rC_Connect__Batch_Upload__c creation
        for(Contact con : contactList) {
            emailList.add(TestUtils.createEmail(con.id, 'test.random1.user@aclu.org.randomUser' , false));
            phoneList.add(TestUtils.createPhone(con.Id, '9876543210', false));
            
            rC_Connect__Batch_Upload__c bU = TestUtils.createBatchUpload(con.Lastname, 'Source', con.Id, 'test.random1.user@aclu.org.randomUser', false);
            batchUploadList.add(bU);
        }
        insert emailList;
        insert phoneList;
    }
    
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
                batchUploadList.add(batchUpload); 
            }
        }
    }
     @isTest
    static void testStatusUpdates() {
        createTestData();
        rc_bios__Address__c address = new rc_bios__Address__c(); 
        address.rc_bios__Postal_Code__c = '23412';
        address.rc_bios__Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
        insert address;

        List<rC_Connect__Batch_Upload__c> uploadLst = new List<rC_Connect__Batch_Upload__c>{batchUploadList[11], batchUploadList[12]};
        uploadLst[0].Error_Count__c = 1;
        uploadLst[1].Error_Count__c = 1;
        insert uploadLst;

        rC_BUP__Event__c eventAddress = new rC_BUP__Event__c();
        eventAddress.rC_BUP__Batch_Upload__c = uploadLst[0].Id;
        eventAddress.rC_BUP__Topic_Sequence__c = 2;
        eventAddress.rC_BUP__Topic_Name__c = 'Address_Topic'; 
        eventAddress.rC_BUP__Event_State__c = 'Processed';
        insert eventAddress;
        
        rC_BUP__Queue__c queueAddress = new rC_BUP__Queue__c();
        queueAddress.rC_BUP__Process_Name__c = 'Address_1_Process';
        queueAddress.rC_BUP__Retriver_Info__c = '{"rc_connect__address_status__c":"Inserted","rc_connect__batch_upload_address_matched__c":"a0BW000000MGXBwMA5"}';
        queueAddress.rC_BUP__Queue_State__c = 'Processed';
        queueAddress.rC_BUP__Process_Sequence__c = 1;
        queueAddress.rC_BUP__Event__c = eventAddress.Id;
        insert queueAddress;

        rC_BUP__Queue__c queueAddress2 = new rC_BUP__Queue__c();
        queueAddress2.rC_BUP__Process_Name__c = 'Address_2_Process';
        queueAddress2.rC_BUP__Retriver_Info__c = '{"rc_connect__address_status__c":"Inserted","rc_connect__batch_upload_address_matched__c":"a0BW000000MGXBwMA5"}';
        queueAddress2.rC_BUP__Queue_State__c = 'Processed';
        queueAddress2.rC_BUP__Process_Sequence__c = 2;
        queueAddress2.rC_BUP__Event__c = eventAddress.Id;
        insert queueAddress2;

        rC_BUP__Event__c events = new rC_BUP__Event__c();
        events.rC_BUP__Batch_Upload__c = uploadLst[0].Id;
        events.rC_BUP__Topic_Sequence__c = 11;
        events.rC_BUP__Topic_Name__c = 'Account_Address_Topic'; 
        events.rC_BUP__Event_State__c = 'Suspend';
        insert events;
        
        rC_BUP__Queue__c queueAccAddress1 = new rC_BUP__Queue__c();
        queueAccAddress1.rC_BUP__Process_Name__c = 'Account_Address_1_Process';
        queueAccAddress1.rC_BUP__Retriver_Info__c = '{"rc_connect__address_status__c":"Inserted","rc_connect__batch_upload_address_matched__c":"a0BW000000MGXBwMA5"}';
        queueAccAddress1.rC_BUP__Queue_State__c = 'Suspend';
        queueAccAddress1.rC_BUP__Process_Sequence__c = 1;
        queueAccAddress1.rC_BUP__Event__c = events.Id;
        insert queueAccAddress1;

        String ACCOUNT_ADDRESS_PREFIX = rC_Bios__Account_Address__c.sobjecttype.getDescribe().getKeyPrefix();
        Test.startTest();
            uploadLst[0].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = 'insufficient access rights on '+ACCOUNT_ADDRESS_PREFIX+' UNABLE_TO_LOCK_ROW';
            uploadLst[0].rC_Connect__Batch_Upload_Status__c = 'Flagged';
            //uploadLst[0].Error_Count__c = 1;
            
            uploadLst[1].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = 'duplicate value found: SB_User_Id__c duplicates value on record with id: BUP_CommitDomain';
            uploadLst[1].rC_Connect__Batch_Upload_Status__c = 'Flagged';
            update uploadLst;
            
            List<rC_Connect__Batch_Upload__c> batchUploadUpdateLst = [  SELECT  Id, rC_Connect__Batch_Upload_Status__c 
                                                                        FROM    rC_Connect__Batch_Upload__c
                                                                        WHERE   Id =: uploadLst[0].Id 
                                                                        OR      Id =: uploadLst[1].Id
                                                                        ORDER BY rC_Connect__Batch_Upload_Status__c];
                                                                        
            system.assertEquals(Label.Status_Ready_for_RoundData, batchUploadUpdateLst[0].rC_Connect__Batch_Upload_Status__c);
            system.assertEquals(Label.Status_Ready_for_RoundData, batchUploadUpdateLst[1].rC_Connect__Batch_Upload_Status__c);

        Test.stopTest();
    }
    @isTest
    static void testBatchUploadStatusUpdates() {
        createTestData();
        List<rC_Connect__Batch_Upload__c> uploadLst = new List<rC_Connect__Batch_Upload__c>{batchUploadList[11], batchUploadList[12]};
        insert uploadLst;
        
        uploadLst[0].rC_Connect__Batch_Upload_Status__c = 'To ZDM';
        uploadLst[1].rC_Connect__Batch_Upload_Status__c = 'To ZDM';
        update uploadLst;
        
        Test.startTest();
            
            uploadLst[0].kwrc__KW_Error_Code__c = 'OK';
            uploadLst[0].rC_Connect__Giving_Giving_Amount__c = 100;
            uploadLst[1].kwrc__KW_Error_Code__c = 'OK';
        
            update uploadLst;
            
            List<rC_Connect__Batch_Upload__c> batchUploadUpdateLst = [  SELECT  Id, rC_Connect__Batch_Upload_Status__c 
                                                                        FROM    rC_Connect__Batch_Upload__c
                                                                        WHERE   Id =: uploadLst[0].Id 
                                                                        ORDER BY rC_Connect__Batch_Upload_Status__c];
                                                                     
            system.assertEquals(Label.Status_New, batchUploadUpdateLst[0].rC_Connect__Batch_Upload_Status__c);
            
            List<rC_Connect__Batch_Upload__c> batchUploadUpdateLst1 = [  SELECT  Id, rC_Connect__Batch_Upload_Status__c 
                                                                        FROM    rC_Connect__Batch_Upload__c
                                                                        WHERE   Id =: uploadLst[1].Id 
                                                                        ORDER BY rC_Connect__Batch_Upload_Status__c];
            system.assertEquals(Label.Status_Ready_for_RoundData, batchUploadUpdateLst1[0].rC_Connect__Batch_Upload_Status__c);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchUploadPaymentMethodInactiveAndDuplicate(){
        List< Account > accList = new LIst< Account> ();
        Account acc = TestUtils.createAccount('FirstAccount', false);
        accList.add(acc);
        Account acc2 = TestUtils.createAccount('SecondAccount', false);
        accList.add(acc2);
        insert accList;
        
        List< RC_Giving__Payment_Method__c > paymentMethodsTypeList = new List< RC_Giving__Payment_Method__c > ();
        RC_Giving__Payment_Method__c meth1 = testUtils.createPaymentMethod( acc.id, false );
        meth1.rC_Giving__Payment_Type__c = 'Paypal';
        meth1.rC_Connect__Payment_Processor__c = 'Heartland';
        meth1.RecordTypeId = Schema.SObjectType.rC_Giving__Payment_Method__c.getRecordTypeInfosByName().get('Paypal').getRecordTypeId();
        //meth1.rC_Connect__Merchant_Name__c = '----';
        paymentMethodsTypeList.add(meth1);
        
        RC_Giving__Payment_Method__c meth2 = testUtils.createPaymentMethod( acc.id, false );
        meth2.rC_Giving__Payment_Type__c = 'Paypal';
        meth2.rC_Connect__Payment_Processor__c = 'Heartland';
        meth2.RecordTypeId = Schema.SObjectType.rC_Giving__Payment_Method__c.getRecordTypeInfosByName().get('Paypal').getRecordTypeId();
        //meth2.rC_Connect__Merchant_Name__c = '----';
        //paymentMethodsTypeList.add(meth2);
        
        RC_Giving__Payment_Method__c meth3 = testUtils.createPaymentMethod( acc2.id, false );
        meth3.rC_Giving__Payment_Type__c = 'EFT';
        meth3.rC_Connect__Payment_Processor__c = 'Litle';
        //meth3.rC_Connect__Merchant_Name__c = '----';
        paymentMethodsTypeList.add(meth3);
        insert paymentMethodsTypeList;
        
        
        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload1.Name = 'Contact Test Batch';
        batchUpload1.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        batchUpload1.rC_Connect__Payment_Method_Payment_Type__c = 'Paypal';
        batchUploadList.add(batchUpload1); 
        rC_Connect__Batch_Upload__c batchUpload2 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload2.Name = 'Contact Test Batch2';
        batchUpload2.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        batchUpload2.rC_Connect__Payment_Method_Payment_Type__c = 'EFT';
        batchUploadList.add(batchUpload2);
        rC_Connect__Batch_Upload__c batchUpload3 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload3.Name = 'Contact Test Batch3';
        batchUpload3.rC_Connect__Batch_Upload_Account_Matched__c = acc2.id;
        batchUpload3.rC_Connect__Payment_Method_Payment_Type__c = 'Paypal';
        batchUploadList.add(batchUpload3);
        insert batchUploadList;
        
        System.assertEquals(acc.id,  [Select rC_Connect__Batch_Upload_Account_Matched__c FROM rC_Connect__Batch_Upload__c 
                                      where id = : batchUpload1.id].rC_Connect__Batch_Upload_Account_Matched__c);
        insert meth2;
        
        Test.startTest();
        System.debug('paymentMethodsTypeList :: ' + paymentMethodsTypeList);
        batchUploadList[0].rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = 'Paymnet Method IDs: {'+meth1.Id+','+meth2.Id+'}';
        batchUploadList[0].rC_Connect__Batch_Upload_Status__c = 'Matching Error';
        batchUploadList[0].rC_Connect__Batch_Upload_Flagged_Reason__c = 'More than one match on Account';
        
        //batchUploadList[0].rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        //batchUploadList[1].rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        //batchUploadList[2].rC_Connect__Batch_Upload_Account_Matched__c = acc2.id; 
        update batchUploadList;
        Test.stopTest();
        
        System.assertEquals(meth2.id, [Select rC_Connect__Batch_Upload_Payment_Method_Matched__c FROM rC_Connect__Batch_Upload__c 
                                       where id = : batchUpload1.id].rC_Connect__Batch_Upload_Payment_Method_Matched__c);
        System.assertEquals('Ready', [Select rC_Connect__Batch_Upload_Status__c FROM rC_Connect__Batch_Upload__c 
                                      where id = : batchUpload1.id].rC_Connect__Batch_Upload_Status__c);
        System.assertEquals(false, [Select rC_Giving__Is_Active__c FROM rC_Giving__Payment_Method__c 
                                    where id = : meth1.id].rC_Giving__Is_Active__c);
    }
    
    public static TestMethod void testBUInsertCountryCodeUpdate(){
        List<Country_Codes__c> ccLIst = new List<Country_Codes__c>();
        Country_Codes__c cc1 = new Country_Codes__c(Name = 'Afghanistan', Country_Code__c = 'AF', Country_3_Char_Code__c = 'AFG');
        Country_Codes__c cc2 = new Country_Codes__c(Name = 'Aland Islands', Country_Code__c = 'AX', Country_3_Char_Code__c = 'ALA');
        Country_Codes__c cc3 = new Country_Codes__c(Name = 'Albania', Country_Code__c = 'AL', Country_3_Char_Code__c = 'ALB');
        Country_Codes__c cc4 = new Country_Codes__c(Name = 'Algeria', Country_Code__c = 'DZ', Country_3_Char_Code__c = 'DZA');
        Country_Codes__c cc5 = new Country_Codes__c(Name = 'American Samoa', Country_Code__c = 'AS', Country_3_Char_Code__c = 'ASM');
        ccLIst.add(cc1);
        ccLIst.add(cc2);
        ccLIst.add(cc3);
        ccLIst.add(cc4);
        ccLIst.add(cc5);
        insert ccList;
        
        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload1.Name = 'Contact Test Batch';
        batchUpload1.rC_Connect__Address_Country__c = 'AFG';
        batchUploadList.add(batchUpload1); 
        rC_Connect__Batch_Upload__c batchUpload2 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload2.Name = 'Contact Test Batch2';
        batchUpload2.rC_Connect__Address_Country__c = 'ALA';
        batchUploadList.add(batchUpload2);
        rC_Connect__Batch_Upload__c batchUpload3 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload3.Name = 'Contact Test Batch3';
        batchUpload3.rC_Connect__Address_Country__c = 'ASM';
        batchUploadList.add(batchUpload3);
        rC_Connect__Batch_Upload__c batchUpload4 = TestUtils.createBatchUpload('TESTBATCH','TESTING',null,'',false);
        batchUpload4.Name = 'Contact Test Batch3';
        batchUploadList.add(batchUpload4);
        
        
        Test.StartTest();
            insert batchUploadList;
            System.assertEquals('AF', [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                       FROM rC_Connect__Batch_Upload__c 
                                       where id = : batchUpload1.id LIMIT 1].rC_Connect__Address_Country__c);
            System.assertEquals('AX', [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                        FROM rC_Connect__Batch_Upload__c 
                                        where id = : batchUpload2.id LIMIT 1].rC_Connect__Address_Country__c);
            System.assertEquals('AS', [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                        FROM rC_Connect__Batch_Upload__c 
                                        where id = : batchUpload3.id LIMIT 1].rC_Connect__Address_Country__c);
            System.assertEquals('Afghanistan', [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                                FROM rC_Connect__Batch_Upload__c 
                                                where id = : batchUpload1.id LIMIT 1].Country_Full_Name__c);
            System.assertEquals('Aland Islands', [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                                    FROM rC_Connect__Batch_Upload__c 
                                                    where id = : batchUpload2.id LIMIT 1].Country_Full_Name__c);
            System.assertEquals('American Samoa', [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                                    FROM rC_Connect__Batch_Upload__c 
                                                    where id = : batchUpload3.id LIMIT 1].Country_Full_Name__c);
            System.assertEquals(null, [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                        FROM rC_Connect__Batch_Upload__c 
                                        where id = : batchUpload4.id LIMIT 1].Country_Full_Name__c);
            System.assertEquals(null, [Select id, rC_Connect__Address_Country__c, Country_Full_Name__c 
                                        FROM rC_Connect__Batch_Upload__c 
                                        where id = : batchUpload4.id LIMIT 1].rC_Connect__Address_Country__c);
        Test.StopTest();
    }
    
    
    private static TestMethod void testBUPreferredAddress(){
        List<account> accountList = new List<Account>();
        Account acc1 = TestUtils.createAccount('Account1', false);
        acc1.BillingStreet = 'Test-1,Block-1';
        acc1.BillingCity = 'Jaipur';
        acc1.BillingPostalCode = '303030';
        acc1.ShippingStreet = 'Test-1,Block-1';
        acc1.ShippingCity = 'Jaipur';
        acc1.ShippingPostalCode = '303030';
        accountList.add(acc1);
        
        Account acc2 = TestUtils.createAccount('Account2', false);
        acc2.BillingStreet = 'Test-2,Block-2';
        acc2.BillingCity = 'Pune';
        acc2.BillingPostalCode = '303032';
        acc2.ShippingStreet = 'Test-2,Block-2';
        acc2.ShippingCity = 'Pune';
        acc2.ShippingPostalCode = '303032';
        accountList.add(acc2);
        
        Account acc3 = TestUtils.createAccount('Account3', false);
        acc3.BillingStreet = 'Test-3,Block-3';
        acc3.BillingCity = 'Mumbai';
        acc3.BillingPostalCode = '390909';
        acc3.ShippingStreet = 'Test-3,Block-3';
        acc3.ShippingCity = 'Mumbai';
        acc3.ShippingPostalCode = '390909';
        accountList.add(acc3);
        insert accountList;
        
        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH1','TESTING1',null,'',false);
        batchUpload1.Name = 'Contact Test Batch';
        batchUpload1.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload1.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload1.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUpload1.SB_Content_Type__c = 'Advocacy Action';
        batchUpload1.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload1); 
        
        rC_Connect__Batch_Upload__c batchUpload2 = TestUtils.createBatchUpload('TESTBATCH2','TESTING2',null,'',false);
        batchUpload2.Name = 'Contact Test Batch2';
        batchUpload2.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUpload2.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload2.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload2.rC_Connect__Address_Street_Line_1__c = 'Test-1,';
        batchUpload2.rC_Connect__Address_Street_Line_2__c = 'Block-1';
        batchUpload2.rC_Connect__Address_City__c = 'Jaipur';
        batchUpload2.rC_Connect__Address_Postal_Code__c = '303030';
        batchUpload2.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUpload2.SB_Content_Type__c = 'springboard_petition';
        batchUploadList.add(batchUpload2);
        
        rC_Connect__Batch_Upload__c batchUpload3 = TestUtils.createBatchUpload('TESTBATCH3','TESTING3',null,'',false);
        batchUpload3.Name = 'Contact Test Batch3';
        batchUpload3.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUpload3.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload3.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload3.rC_Connect__Address_Street_Line_1__c = 'Test-2,';
        batchUpload3.rC_Connect__Address_Street_Line_2__c = 'Block-1';
        batchUpload3.rC_Connect__Address_City__c = 'Jaipur';
        batchUpload3.rC_Connect__Address_Postal_Code__c = '303030';
        batchUpload3.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUpload3.SB_Content_Type__c = 'sba_message_action';
        batchUploadList.add(batchUpload3);
        
        rC_Connect__Batch_Upload__c batchUpload4 = TestUtils.createBatchUpload('TESTBATCH4','TESTING4',null,'',false);
        batchUpload4.Name = 'Contact Test Batch3';
        batchUpload4.rC_Connect__Batch_Upload_Account_Matched__c = acc2.id;
        batchUpload4.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload4.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload4.rC_Connect__Address_Street_Line_1__c = 'Test-2,';
        batchUpload4.rC_Connect__Address_Street_Line_2__c = 'Block-2';
        batchUpload4.rC_Connect__Address_City__c = 'Pune';
        batchUpload4.rC_Connect__Address_Postal_Code__c = '303032';
        batchUpload4.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUpload4.SB_Content_Type__c = 'sba_social_action';
        batchUploadList.add(batchUpload4);
        
        rC_Connect__Batch_Upload__c batchUpload5 = TestUtils.createBatchUpload('TESTBATCH5','TESTING5',null,'',false);
        batchUpload5.Name = 'Contact Test Batch3';
        batchUpload5.rC_Connect__Batch_Upload_Account_Matched__c = acc3.id;
        batchUpload5.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload5.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload5.rC_Connect__Address_Street_Line_1__c = 'Test-3,';
        batchUpload5.rC_Connect__Address_Street_Line_2__c = 'Block-3';
        batchUpload5.rC_Connect__Address_City__c = 'Mumbai';
        batchUpload5.rC_Connect__Address_Postal_Code__c = '390909';
        batchUpload5.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUpload5.SB_Content_Type__c = 'webform';
        batchUploadList.add(batchUpload5);
        
        rC_Connect__Batch_Upload__c batchUpload6 = TestUtils.createBatchUpload('TESTBATCH6','TESTING6',null,'',false);
        batchUpload6.Name = 'Contact Test Batch3';
        batchUpload6.rC_Connect__Batch_Upload_Account_Matched__c = acc3.id;
        batchUpload6.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload6.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload6.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUpload6.SB_Content_Type__c = 'volunteer_form';
        batchUploadList.add(batchUpload6);
        
        rC_Connect__Batch_Upload__c batchUpload7 = TestUtils.createBatchUpload('TESTBATCH7','TESTING7',null,'',false);
        batchUpload7.Name = 'Contact Test Batch3';
        batchUpload7.rC_Connect__Batch_Upload_Account_Matched__c = acc3.id;
        batchUpload7.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload7.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload7.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUpload7.SB_Content_Type__c = 'Email Sign Up';
        batchUploadList.add(batchUpload7);
        
        rC_Connect__Batch_Upload__c batchUpload8 = TestUtils.createBatchUpload('TESTBATCH8','TESTING8',null,'',false);
        batchUpload8.Name = 'Contact Test Batch3';
        batchUpload8.rC_Connect__Batch_Upload_Account_Matched__c = acc3.id;
        batchUpload8.rC_Connect__Address_Preferred_Billing__c = false;
        batchUpload8.rC_Connect__Address_Preferred_Shipping__c = false;
        batchUpload8.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload8);
        
        rC_Connect__Batch_Upload__c batchUpload9 = TestUtils.createBatchUpload('TESTBATCH9','TESTING9',null,'',false);
        batchUpload9.Name = 'Contact Test Batch';
        batchUpload9.rC_Connect__Address_Preferred_Billing__c = true;
        batchUpload9.rC_Connect__Address_Preferred_Shipping__c = true;
        batchUpload9.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUploadList.add(batchUpload9); 
        
        insert batchUploadList;
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload1.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload1.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload2.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload2.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload3.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload3.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload4.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload4.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload5.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload5.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload6.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload6.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload7.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload7.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload8.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(true, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                   where id = : batchUpload8.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        System.assertEquals(false, [Select id, rC_Connect__Address_Preferred_Billing__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload9.id ].rC_Connect__Address_Preferred_Billing__c);
        System.assertEquals(false, [Select id, rC_Connect__Address_Preferred_Shipping__c from rC_Connect__Batch_Upload__c 
                                    where id = : batchUpload9.id ].rC_Connect__Address_Preferred_Shipping__c);
        
        for(rC_Connect__Batch_Upload__c bu : batchUploadList){
            bu.rC_Connect__Batch_Upload_Status__c = 'FromRDReady';
        }
        batchUploadList[0].rC_Connect__Batch_Upload_Status__c = 'FromRDNew';
        update batchUploadList;
        
    }

    //AK
    public static TestMethod void testUpdatePreferredContact(){
        List<account> accountList = new List<Account>();
        Account acc1 = TestUtils.createAccount('Account1', false);
        accountList.add(acc1);
        
        Account acc2 = TestUtils.createAccount('Account2', false);
        accountList.add(acc2);
        
        insert accountList;
        
        List<Contact> contactList = new List<Contact>();
        Contact cont1 = TestUtils.createContact(acc1,'cons1','TestConBatch1',false);
        contactList.add(cont1);
        Contact cont2 = TestUtils.createContact(acc1,'cons2','TestConBatch2',false);
        contactList.add(cont2);
        Contact cont3 = TestUtils.createContact(acc2,'cons3','TestConBatch3',false);
        contactList.add(cont3);
        insert contactList;
        
        //acc1.rC_Bios__Secondary_Contact__c = cont2.id;
        //update acc1;
        
        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH1','TESTING1',null,'',false);
        batchUpload1.Name = 'Contact Test Batch';
        batchUpload1.rC_Connect__Batch_Upload_Contact_1_Matched__c = cont1.id;
        batchUpload1.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUpload1.SB_Content_Type__c = 'Advocacy Action';
        batchUpload1.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload1); 
        
        rC_Connect__Batch_Upload__c batchUpload2 = TestUtils.createBatchUpload('TESTBATCH2','TESTING2',null,'',false);
        batchUpload2.Name = 'Contact Test Batch2';
        batchUpload2.rC_Connect__Batch_Upload_Account_Matched__c = acc2.id;
        batchUpload2.rC_Connect__Batch_Upload_Contact_1_Matched__c = cont3.id;
        batchUpload2.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload2);
        insert batchUploadList;
        batchUploadList.clear();
        
        batchUpload1.rC_Connect__Batch_Upload_Status__c = 'Committed';
        //batchUpload1.rC_Connect__Account_Status__c = 'Inserted';
        batchUpload1.rC_Connect__Contact1_Status__c = 'Inserted';
        batchUploadList.add(batchUpload1);
        batchUpload2.rC_Connect__Batch_Upload_Status__c = 'Committed';
        batchUpload2.rC_Connect__Account_Status__c = 'Updated';
        batchUpload2.rC_Connect__Contact1_Status__c = 'Inserted';
        batchUploadList.add(batchUpload2);
        update batchUploadList;
        
        System.assertEquals(True, [Select rC_Bios__Preferred_Contact__c From contact where id =: cont1.id].rC_Bios__Preferred_Contact__c);
        System.assertEquals(True, [Select rC_Bios__Preferred_Contact__c From contact where id =: cont3.id].rC_Bios__Preferred_Contact__c);
    }
    
    //T-652003
    public static TestMethod void testUpdateSecondaryContact(){
        List<account> accountList = new List<Account>();
        Account acc1 = TestUtils.createAccount('Account1', false);
        accountList.add(acc1);
        
        Account acc2 = TestUtils.createAccount('Account2', false);
        accountList.add(acc2);
        
        insert accountList;
        
        List<Contact> contactList = new List<Contact>();
        Contact cont1 = TestUtils.createContact(acc1,'cons1','TestConBatch1',false);
        contactList.add(cont1);
        Contact cont2 = TestUtils.createContact(acc1,'cons2','TestConBatch2',false);
        contactList.add(cont2);
        Contact cont3 = TestUtils.createContact(acc2,'cons3','TestConBatch3',false);
        contactList.add(cont3);
        insert contactList;
        
        acc1.rC_Bios__Secondary_Contact__c = cont2.id;
        //update acc1;
        
        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH1','TESTING1',null,'',false);
        batchUpload1.Name = 'Contact Test Batch';
        batchUpload1.rC_Connect__Batch_Upload_Contact_2_Matched__c = cont1.id;
        batchUpload1.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUpload1.SB_Content_Type__c = 'Advocacy Action';
        batchUpload1.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload1); 
        
        rC_Connect__Batch_Upload__c batchUpload2 = TestUtils.createBatchUpload('TESTBATCH2','TESTING2',null,'',false);
        batchUpload2.Name = 'Contact Test Batch2';
        batchUpload2.rC_Connect__Batch_Upload_Account_Matched__c = acc2.id;
        batchUpload2.rC_Connect__Batch_Upload_Contact_2_Matched__c = cont3.id;
        batchUpload2.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload2);
        insert batchUploadList;
        batchUploadList.clear();
        
        batchUpload1.rC_Connect__Batch_Upload_Status__c = 'Committed';
        //batchUpload1.rC_Connect__Account_Status__c = 'Inserted';
        batchUpload1.rC_Connect__Contact2_Status__c = 'Inserted';
        batchUploadList.add(batchUpload1);
        batchUpload2.rC_Connect__Batch_Upload_Status__c = 'Committed';
        batchUpload2.rC_Connect__Account_Status__c = 'Updated';
        batchUpload2.rC_Connect__Contact2_Status__c = 'Inserted';
        batchUploadList.add(batchUpload2);
        update batchUploadList;
        
        System.assertEquals(True, [Select rC_Bios__Secondary_Contact__c From contact where id =: cont1.id].rC_Bios__Secondary_Contact__c);
        System.assertEquals(True, [Select rC_Bios__Secondary_Contact__c From contact where id =: cont3.id].rC_Bios__Secondary_Contact__c);
    }
    
    public static TestMethod void testGivingUpgradeAmountUpdate() {
        list<rC_Connect__Batch_Upload__c> batchUploadList = new list<rC_Connect__Batch_Upload__c>();
        for(Integer i=0; i<15; i++) {
            rC_Connect__Batch_Upload__c batchUpload = TestUtils.createBatchUpload('TESTBATCH'+i,'TESTING'+i,null,'',false);
            batchUpload.Name = 'Upgrade Amount Test '+i;
            batchUpload.rC_Connect__Batch_Upload_Status__c = 'New';
            batchUpload.rC_Connect__Batch_Upload_Source_File__c = 'Springboard';
            batchUpload.rC_Connect__Giving_Record_Type__c = 'Pledge';
            batchUpload.rC_Connect__Giving_Paid__c = true;
            batchUpload.rC_Connect__Giving_Giving_Amount__c = 100;
            batchUpload.Cont1_Email__c = 'Test@example.com';
            batchUpload.Cont1_OptIn__c = true;
            batchUploadList.add(batchUpload); 
        }
        insert batchUploadList;
        for(rC_Connect__Batch_Upload__c b : [SELECT Id, Upgrade_Amount__c, rC_Connect__Giving_Giving_Amount__c 
                                                FROM rC_Connect__Batch_Upload__c
                                                WHERE Id IN :batchUploadList]) {
            system.assertEquals(b.rC_Connect__Giving_Giving_Amount__c, b.Upgrade_Amount__c);                                          
        }
    }
    
    public static TestMethod void updateTransactionExternalId(){
        String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        Account acc = TestUtils.createAccount('Account1', true);
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;
        Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp2.recordTypeId = OPPORTUNITY_RT_DONATION_Id;//Parent
        opp2.rC_Giving__Giving_Amount__c = 1000;
        opp2.IsCreatedFromBatchLog__c = true;
        opp2.Fees__c = 800;
        opp2.CampaignId = cmp.id;
        opp2.Ack_Recipient_Account__c = acc.id;
        opp2.rC_Giving__Payment_Method__c = 'Charge Card';
        opp2.stagename='open';
        opp2.Adjustment_Code__c = 'D';
        opp2.Batch_Sequence__c = '1';
        insert opp2;
        Opportunity opp4 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);//Transaction
        opp4.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        opp4.rC_Giving__Parent__c = opp2.id;
        opp4.rC_Giving__Giving_Amount__c = 1000;
        insert opp4;
        
        
        rC_Connect__Batch_Upload__c bu = TestUtils.createBatchUpload('TESTBATCH','TESTING6',null,'',false);
        bu.Name = 'Contact Test Batch3';
        bu.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        bu.rC_Connect__Giving_Giving_Amount__c = 100;
        bu.SB_Content_Type__c = 'volunteer_form';
        bu.rC_Connect__Batch_Upload_Status__c = 'New';
        bu.Transaction_External_Id__c = 'Test-1234';
        bu.isSoft_Credit__c = FALSE;
        bu.rC_Connect__Batch_Upload_Giving_Matched__c = opp2.id;
        insert bu;
        
        bu.rC_Connect__Batch_Upload_Status__c = 'Committed';
        bu.Transaction_External_Id__c = 'Test-1234';
        bu.isSoft_Credit__c = FALSE;
        update bu;
        System.assertEquals('Test-1234', [select id,External_ID__c from Opportunity where id =: opp4.id].External_ID__c);
    }
    
    public static TestMethod void updateSoftCreditStage(){
        String OPPORTUNITY_RT_SOFT_CREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
        Account acc = TestUtils.createAccount('Account1', true);
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;
        Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp2.recordTypeId = OPPORTUNITY_RT_SOFT_CREDIT_Id;//soft credit
        opp2.rC_Giving__Giving_Amount__c = 1000;
        opp2.IsCreatedFromBatchLog__c = true;
        opp2.Fees__c = 800;
        opp2.CampaignId = cmp.id;
        opp2.Ack_Recipient_Account__c = acc.id;
        opp2.rC_Giving__Payment_Method__c = 'Charge Card';
        opp2.stagename='Completed';
        opp2.Adjustment_Code__c = 'D';
        opp2.Batch_Sequence__c = '1';
        insert opp2;
        
        
        
        rC_Connect__Batch_Upload__c bu = TestUtils.createBatchUpload('TESTBATCH','TESTING6',null,'',false);
        bu.Name = 'Contact Test Batch3';
        bu.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        bu.rC_Connect__Giving_Giving_Amount__c = 100;
        bu.SB_Content_Type__c = 'volunteer_form';
        bu.rC_Connect__Batch_Upload_Status__c = 'New';
        bu.Transaction_External_Id__c = 'Test-1234';
        bu.isSoft_Credit__c = True;
        bu.rC_Connect__Batch_Upload_Giving_Matched__c = opp2.id;
        insert bu;
        
        bu.rC_Connect__Batch_Upload_Status__c = 'Committed';
        bu.Transaction_External_Id__c = 'Test-1234';
        bu.TPA_Bypass__c = True;
        update bu;
        System.assertEquals('Open', [select id,stagename from Opportunity where id =: opp2.id].stagename);
    }
	
	//Modified by :roundCorner Inc. 06-Dec-18 :: Ticket#61850
    //The intetion here to create a async request is to update account billing address if its blank and 
    //BU has the value in custom address fields
    public static TestMethod void testAccountCustomCommit(){
        List<account> accountList = new List<Account>();
        Account acc1 = TestUtils.createAccount('Account1', false);
        accountList.add(acc1);
        
        acc1.BillingCity = 'CT';

        insert accountList;

        List<Contact> contactList = new List<Contact>();
        Contact cont1 = TestUtils.createContact(acc1,'cons1','TestConBatch1',false);
        contactList.add(cont1);
        Contact cont2 = TestUtils.createContact(acc1,'cons2','TestConBatch2',false);
        contactList.add(cont2);
        insert contactList;

        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH1','TESTING1',null,'',false);
        batchUpload1.Name = 'Test Custom Commit Batch';
        batchUpload1.rC_Connect__Batch_Upload_Contact_1_Matched__c = cont1.id;
        batchUpload1.rC_Connect__Batch_Upload_Account_Matched__c = acc1.id;
        batchUpload1.SB_Content_Type__c = 'Advocacy Action';
        batchUpload1.rC_Connect__Giving_Giving_Amount__c = 100;
        batchUploadList.add(batchUpload1); 
        insert batchUploadList;
        batchUploadList.clear();

        Test.startTest();

        batchUpload1.rC_Connect__Batch_Upload_Status__c = 'Committed';
        batchUpload1.rC_Connect__Contact1_Status__c = 'Inserted';
        batchUpload1.Custom_City__c = 'CT2';
        batchUpload1.Custom_State__c = 'ST';
        batchUploadList.add(batchUpload1);
        update batchUploadList;
        Test.stopTest();

        //System.assertEquals(1, [Select count() FROM AsyncRequest__c], [Select Id, Error__c, Error_Message__c FROM AsyncRequest__c]);

        System.assertEquals(batchUpload1.Custom_State__c, [Select BillingCity, BillingState From Account where id =: acc1.id].BillingState);
        System.assertEquals('CT', [Select BillingCity, BillingState From Account where id =: acc1.id].BillingCity);
    }
    
    //Created By :: Zendesk #67681
    public static TestMethod void testOpportunityAffiliationChangeTest() {
        
        String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        Account acc = TestUtils.createAccount('Account123',false);
        acc.Affiliation__c = 'AA';
        acc.BillingPostalCode = '00000';
        acc.BillingCountry = 'Japan';
        acc.Has_Renewed_Before__c = false;
        insert acc; 
        rc_bios__Address__c address = new rc_bios__Address__c(); 
        address.rc_bios__Postal_Code__c = '23412';
        address.rc_bios__Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
        insert address;
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Opportunity opp= CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false,donationOppPaymentId,null);
        insert opp;
        opp.Account_Affiliation__c = 'CN';
        update opp;
        Opportunity opp2= CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false,pledgeOppPaymentId,opp.id);
        opp2.Account_Affiliation__c = 'CN';
        opp2.rC_Giving__Parent__c = opp.id;
        insert opp2;
        opp2.Account_Affiliation__c = 'CN';
        update opp2;
        
        rC_Connect__Batch_Upload__c bu = TestUtils.createBatchUpload('TESTBATCH','TESTING6',null,'',false);
        bu.Name = 'Contact Test Batch3';
        bu.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        bu.rC_Connect__Giving_Giving_Amount__c = 100;
        bu.SB_Content_Type__c = 'volunteer_form';
        bu.rC_Connect__Batch_Upload_Status__c = 'New';
        bu.Transaction_External_Id__c = 'Test-1234';
        bu.isSoft_Credit__c = FALSE;
        bu.rC_Connect__Batch_Upload_Giving_Matched__c = opp.id;
        bu.rC_Connect__Batch_Upload_Address_Matched__c = address.id;
        bu.rC_Connect__Giving_Close_Date__c = Date.today().addMonths(4);
        insert bu;
        
        bu.rC_Connect__Batch_Upload_Status__c = 'Committed';
        update bu;
        List<Opportunity> opList = [SELECT id,Account_Affiliation__c FROM Opportunity WHERE rC_Giving__Parent__c != null  LIMIT 1]; 
        System.assertEquals(opList[0].Account_Affiliation__c == opp2.Account_Affiliation__c, true);
    }
     // Not using the method present in the TestUtilis as requires custom fields for long records:: //Created By :: Zendesk #67681
    public static Opportunity createOpportunity(Id AccountId, String Name, date closeDate, String sharingCode, String programType, String campaignType, Boolean doInsert, Id recordTypes,Id ParentId){
        Opportunity opp = new Opportunity(Account_Affiliation__c = 'CN', Campaign_Type__c = campaignType,Program_Type__c = programType, RecordtypeId = recordTypes, Sharing_Code__c = sharingCode,rC_Giving__Giving_Amount__c = 20,Amount = 4, AccountId = AccountId ,Name = Name, CloseDate = closeDate, StageName = 'Completed');
        opp.rC_Giving__Parent__c = ParentId;
        opp.StageName = 'Completed';
        opp.CloseDate = Date.today().addMonths(4);
        if(doInsert)
            insert opp;
        return opp;
    }
      //Created By :: Traction #BGE-02    
     public static TestMethod void checkForDuplicateTest() {
         
     String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        Account acc = TestUtils.createAccount('Account123',false);
        acc.Affiliation__c = 'AA';
        acc.BillingPostalCode = '00000';
        acc.BillingCountry = 'Japan';
        acc.Has_Renewed_Before__c = false;
        insert acc; 
        rc_bios__Address__c address = new rc_bios__Address__c(); 
        address.rc_bios__Postal_Code__c = '23412';
        address.rc_bios__Street_Line_1__c = 'test street1 streee2, street3 asdfsadfasdfas';
        insert address;
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Opportunity opp= CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false,donationOppPaymentId,null);
        insert opp;
        opp.Account_Affiliation__c = 'CN';
        update opp;
        Opportunity opp2= CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false,pledgeOppPaymentId,opp.id);
        opp2.Account_Affiliation__c = 'CN';
        opp2.rC_Giving__Parent__c = opp.id;
        insert opp2;
        opp2.Account_Affiliation__c = 'CN';
        update opp2;
        
        List<rC_Connect__Batch_Upload__c> lstBUPs = new list<rC_Connect__Batch_Upload__c>();
        rC_Connect__Batch_Upload__c bu = TestUtils.createBatchUpload('TESTBATCH','TESTING6',null,'',false);
        bu.Name = 'Contact Test Batch3';
        bu.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        bu.rC_Connect__Giving_Giving_Amount__c = 100;
        bu.SB_Content_Type__c = 'volunteer_form';
        bu.rC_Connect__Batch_Upload_Status__c = 'New';
        bu.Transaction_External_Id__c = 'Test-1234';
        bu.isSoft_Credit__c = FALSE;
        bu.rC_Connect__Preferences_1_Code_Value__c = 'NMMEXNO';
        bu.rC_Connect__Preferences_1_Start_Date__c = system.today();
        bu.rC_Connect__Preferences_2_Code_Value__c ='AARTCE';
        bu.rC_Connect__Preferences_2_Start_Date__c = system.today();
        bu.Preferences_4_Code_Value__c = 'AARTCE';
        bu.Preferences_4_Start_Date__c = system.today();
        
        bu.rC_Connect__Batch_Upload_Giving_Matched__c = opp.id;
        bu.rC_Connect__Batch_Upload_Address_Matched__c = address.id;
        bu.rC_Connect__Giving_Close_Date__c = Date.today().addMonths(4);
        lstBUPs.add(bu);
        
        rC_Connect__Batch_Upload__c bu1 = TestUtils.createBatchUpload('TESTBATCH','TESTING6',null,'',false);
        bu1.Name = 'Contact Test Batch3';
        bu1.rC_Connect__Batch_Upload_Account_Matched__c = acc.id;
        bu1.rC_Connect__Giving_Giving_Amount__c = 100;
        bu1.SB_Content_Type__c = 'volunteer_form';
        bu1.rC_Connect__Batch_Upload_Status__c = 'New';
        bu1.Transaction_External_Id__c = 'Test-1234';
        bu1.isSoft_Credit__c = FALSE;
        bu1.rC_Connect__Preferences_1_Code_Value__c = 'NMMEXNO';
        bu1.rC_Connect__Preferences_1_Start_Date__c = system.today();        
        bu1.rC_Connect__Preferences_3_Code_Value__c ='AARTCE';
        bu1.rC_Connect__Preferences_3_Start_Date__c = system.today();
        bu1.Preferences_5_Code_Value__c = 'ACFRFM';
        bu1.Preferences_5_Start_Date__c = system.today();
        
        bu1.rC_Connect__Batch_Upload_Giving_Matched__c = opp.id;
        bu1.rC_Connect__Batch_Upload_Address_Matched__c = address.id;
        bu1.rC_Connect__Giving_Close_Date__c = Date.today().addMonths(4);
        lstBUPs.add(bu1);
        
        insert lstBUPs;
        
        lstBUPs[0].rC_Connect__Batch_Upload_Status__c = 'Committed';
        lstBUPs[1].rC_Connect__Batch_Upload_Status__c = 'Committed';
        
        update lstBUPs;  
      
       
        
        List<rC_Bios__Preference__c> lstPre = [SELECT Id,rC_Bios__Active__c,rC_Bios__End_Date__c,rC_Bios__Contact__c,rC_Bios__Code_Value__c,rC_Bios__Account__c from rC_Bios__Preference__c
                                                          where rC_Bios__Account__c =: acc.id];          
        
         
         System.assertEquals(lstPre.size(), 3);
     }
    
}
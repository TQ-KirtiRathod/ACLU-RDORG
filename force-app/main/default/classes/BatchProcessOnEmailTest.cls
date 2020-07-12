/*
*
*Name  :  BatchProcessOnEmailTest 
*Author:  Appirio : Shobhit Pant
*Date  :  June 15, 2017
*Purpose : Test Class for BatchProcessOnEmail Class
*/
@isTest
public class BatchProcessOnEmailTest {
    @isTest
    static void testBatchProcessWithCustSett(){
        Test.startTest();
        createData(true);
        Database.executeBatch(new BatchProcessOnEmail());
        Test.stopTest();
        System.assertEquals('BatchProcessOnEmail', Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnEmail').Name);
    }
    
    @isTest
    static void testBatchProcessWithoutCustSett(){
        Test.startTest();
        createData(false);
        Database.executeBatch(new BatchProcessOnEmail());
        Test.stopTest();
        System.assertEquals('BatchProcessOnEmail', Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnEmail').Name);
    }
    
    static void createData(Boolean FlagToCreateCustSett){
        List<Email__c> emailList = new List<Email__c>();
        List<sb_action__c> actionList = new List<sb_action__c>();
        
        if(FlagToCreateCustSett){
            //creating custom setting
            Last_Run_Time_Of_Batch__c lrtobj = TestUtils.createLastRunSetting('BatchProcessOnEmail',Date.today().addDays(-5),true);
        }		
        
        //another custom setting to avoid emailtriggerhandler onbeforeinsert error
        Queueable_Control__c qc = TestUtils.createQueueableControl('MainQueueable',100,100, true);
        
        //creating account for contact acc reference
        Account acc = TestUtils.createAccount('testaccount', true);
        
        //creating contact for email cont reference
        Contact con = TestUtils.createContact(acc , 'test' , 'contact' , true);
        
        //Inserting test emails
        for(Integer i = 0; i< 7; i++){
            Email__c email = TestUtils.createEmail(con.Id , 'testEmail' + i , false);
            //giving random values to email- Acquisition Form Id and similar values to Action - Springboard Id
            email.Acquisition_Form_ID__c = '2'+ i + (i+1);
            sb_action__c action = TestUtils.createAction('testAction' + i,Decimal.valueOf('2' + i + (i+1)),false);
            emailList.add(email);
            actionList.add(action);
        }
        //changing Email Acquisition Initial Market SourceChannel for increasing coverage
        if(emailList.size() == 7){
            system.debug('came here');
            emailList.get(0).Acquisition_Initial_Market_SourceChannel__c = 'eml';
            emailList.get(1).Acquisition_Initial_Market_SourceChannel__c = 'fb';
            emailList.get(2).Acquisition_Initial_Market_SourceChannel__c = 'tw';
            emailList.get(3).Acquisition_Initial_Market_SourceChannel__c = 'web';
            emailList.get(4).Acquisition_Initial_Market_SourceChannel__c = 'ban';
            emailList.get(5).Acquisition_Initial_Market_SourceChannel__c = 'gad';
            emailList.get(6).Acquisition_Initial_Market_SourceChannel__c = 'oth';
            insert emailList;
        }
        if(actionList.size() == 7){
            insert actionList;
        }
        
    }
}
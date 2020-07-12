@isTest
private class BatchProcessOnGivingTest {
    static void setup(Boolean isCreateCusSet){
        if(isCreateCusSet){
            //creating custom setting
            Last_Run_Time_Of_Batch__c lrtobj = TestUtils.createLastRunSetting('BatchProcessOnGiving',Date.today().addDays(-5),true);
        }
        /*creating the record of Action*/
        sb_action__c sa = TestUtils.createAction('testAction' ,250,false);
        sa.Secondary_Advocacy_Donation_Count__c=null;
        sa.Secondary_Advocacy_Donation_Sum__c=null;
        insert sa;
        /*creating the record of Account*/
        Account acc = TestUtils.createAccount('Test Acc', true);
        /*creating the records of Opportunity*/
        Id devRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i =0; i<10; i++){
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'Test Opp'+i, false);
            opp.StageName = 'Completed';
            opp.RecordTypeId = devRecordTypeId;
            opp.Adjustment_Code__c = 'N';
            opp.SB_Originating_Form_ID__c='250';
            opp.rC_Giving__Closed_Amount__c = 10;
            oppList.add(opp);
        }
        insert oppList;
    }
    @isTest
    static void testMethod1(){
        setup(true);
        Test.startTest();
        Database.executeBatch(new BatchProcessOnGiving());
        Test.stopTest();
        List<sb_action__c> sa = new List<sb_action__c>([Select Id,Secondary_Advocacy_Donation_Sum__c ,Secondary_Advocacy_Donation_Count__c From sb_action__c where Springboard_ID__c=250]);
        system.assertEquals(10,sa[0].Secondary_Advocacy_Donation_Count__c);    
        system.assertEquals(100,sa[0].Secondary_Advocacy_Donation_Sum__c );
    }
    @isTest
    static void testMethod2(){
        setup(false);
        Test.startTest();
        Database.executeBatch(new BatchProcessOnGiving());
        Test.stopTest();
        List<sb_action__c> sa = new List<sb_action__c>([Select Id,Secondary_Advocacy_Donation_Sum__c ,Secondary_Advocacy_Donation_Count__c From sb_action__c where Springboard_ID__c=250]);
        system.assertEquals(10,sa[0].Secondary_Advocacy_Donation_Count__c);    
        system.assertEquals(100,sa[0].Secondary_Advocacy_Donation_Sum__c );
    }
}
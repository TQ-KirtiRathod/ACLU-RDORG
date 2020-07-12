@isTest
public class MergeManagementControllerTest {
    
    @isTest //method for submiting Tasks
    public static void testMergeManagementController()
    {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.MergeManagement;
        //In this case, the Visualforce page named 'MergeManagement' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        MergeManagementController m = new MergeManagementController();
        m.mergeJobNumber = '121';
        m.mergeJobNumberOpp = '189';
        m.submit();
        m.submitOpp();
        System.assertEquals([SELECT Status FROM Task].get(0).status, 'In Progress');
        Test.stopTest();
    }
    
    @isTest //method for submiting Opportunities
    public static void testMergeManagementController2()
    {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.MergeManagement;
        //In this case, the Visualforce page named 'MergeManagement' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        MergeManagementController m = new MergeManagementController();
        m.mergeJobNumber = '189';
        m.mergeJobNumberOpp = '1';
        m.submit();
        m.submitOpp();
        System.assertEquals([SELECT Merge_Job_Number__c FROM Opportunity].get(0).Merge_Job_Number__c,null);
        System.assertEquals([SELECT Acknowledgment_Status__c FROM Opportunity].get(0).Acknowledgment_Status__c,'N - Not Acknowledged');
        Test.stopTest();
    }
    
    @isTest //Method for the else conditions
    public static void testMergeManagementController3()
    {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.MergeManagement;
        //In this case, the Visualforce page named 'MergeManagement' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        MergeManagementController m = new MergeManagementController();
        m.submit();
        system.assertEquals(true,ApexPages.getMessages()[0].getDetail().containsIgnoreCase('Enter Merge Job Number'));
        m.submitOpp();
        Test.stopTest();
    }
    
    @testSetup //Create Testdata
    static void createTestData() {
        List<Task> taskLst = new List<Task>();
        for(integer i = 0;i<10;i++) {
            Task tsk = TestUtils.createTask(null, 'Completed', false);
            tsk.Fulfilled_Date__c = Date.today() -  i;
            tsk.Merge_Job_Number__c = '121';
            taskLst.add(tsk);
        }
        insert taskLst;
        
        List<Opportunity> oppLst = new List<Opportunity>();
        for(integer i =0;i<10;i++) {
            Opportunity opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.CloseDate = Date.today() + 100;
            opp.rC_Giving__Acknowledged_Date__c = Date.today();
            opp.Acknowledgment_Status__c = 'AK Ack to Susan and Jim about gifts';
            opp.Merge_Job_Number__c = '1';
            oppLst.add(opp);
        }        
        insert oppLst;
    }
}
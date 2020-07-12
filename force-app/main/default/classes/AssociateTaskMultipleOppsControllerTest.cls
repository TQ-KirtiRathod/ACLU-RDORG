@isTest
public class AssociateTaskMultipleOppsControllerTest 
{
    
    public static Account a ;
    public static Task t ;
    public static Opportunity objOppty;
      
    @isTest
    public static void testAssociateTaskMultipleOppsController()
    {
          
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AssociateTaskToMultipleProposals;
        //In this case, the Visualforce page named 'AssociateTaskToMultipleProposals' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        //callled the testRecord method.
        testRecord();
        
        //passing parameter to url
        ApexPages.currentPage().getParameters().put('TaskId',t.Id);
        
        //Instantiate and construct the controller class.
        AssociateTaskMultipleOppsController ass = new AssociateTaskMultipleOppsController();

        //Initialising the wrapperList.
        List<AssociateTaskMultipleOppsController.PledgeOpportunityWrapper> pList = new List<AssociateTaskMultipleOppsController.PledgeOpportunityWrapper>();
        
        //Initialising the wrapperClass
        AssociateTaskMultipleOppsController.PledgeOpportunityWrapper oppWrapperInsert = new AssociateTaskMultipleOppsController.PledgeOpportunityWrapper(true,objOppty);
        pList.add(oppWrapperInsert);
        ass.opptyWrapper = pList;
       
        Test.startTest();
            ass.save();
        Test.stopTest();
        system.assertEquals(2,[SELECT count() FROM Task ]);
        //call Cancel
        ass.Cancel();
    }
    
    
    
    @isTest
    public static void testAssociateTaskMultipleOppsController2()
    {       
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AssociateTaskToMultipleProposals;
        //In this case, the Visualforce page named 'AssociateTaskToMultipleProposals' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        //called the testRecord method
        testRecord();
        
        //Passing parameter to url.
        ApexPages.currentPage().getParameters().put('TaskId',t.Id);
        
        //Instantiate and construct the controller class.
        AssociateTaskMultipleOppsController ass = new AssociateTaskMultipleOppsController();
        
        //Initialising the wrapperList.
        List<AssociateTaskMultipleOppsController.PledgeOpportunityWrapper> pList = new List<AssociateTaskMultipleOppsController.PledgeOpportunityWrapper>();
        AssociateTaskMultipleOppsController.PledgeOpportunityWrapper oppWrapperInsert = new AssociateTaskMultipleOppsController.PledgeOpportunityWrapper(false,objOppty);
        pList.add(oppWrapperInsert);
        ass.opptyWrapper = pList;
         
        Test.startTest();
            ass.save();
        Test.stopTest();
        system.assertEquals(1,[SELECT count() FROM Task ]);

    }
    
     public static void testRecord()
     {
        //create an account
        a = testUtils.createAccount('test', true);
        t = testUtils.createTask('call', 'status', true);
                
        //Create an Opportunity. 
        objOppty = testUtils.createOpportunity(a.id,'oppNew',false);
        objOppty.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        insert objOppty;
     }
    
    
}
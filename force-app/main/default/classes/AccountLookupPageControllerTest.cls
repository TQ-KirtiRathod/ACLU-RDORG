@isTest
private without sharing class AccountLookupPageControllerTest {
    
    private static List<Account> accList = new List<Account>();
    
    @isTest
    private static void testAccountLookupPageController()
    {
        
        accList = TestUtils.createAccounts(true);
        Opportunity opp = testUtils.createOpportunity(accList.get(0).id, 'Name', false);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grant').getRecordTypeId();
        insert opp;
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.Account_Lookup_Page;
        //Set the Parameter
        Test.setCurrentPageReference(pageRef); 
        System.currentPageReference().getParameters().put('isPledge', 'true');
        //In this case, the Visualforce page named 'Account_Lookup_Page' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        //Instantiate and construct the controller class.
        AccountLookupPageController accLPC = new AccountLookupPageController();
        
        System.assertEquals(10,accList.size());
        
        //for runQuery if condition
        String testQuery=accList[0].name;
        accLPC.searchWindow = false;
        accLPC.query=testQuery;
        accLPC.accountCreated=false;
        accLPC.runQuery();
        
        
        
        //for runQuery if else condition
        String testQuery1='m';
        try
        {
            accLPC.accountCreated=true;
            accLPC.query=testQuery1;
            accLPC.runQuery();
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('Search term must be more than two Characters'));
        }
        
        
        
        //for runQuery  else condition
        try
        {
            accLPC.searchWindow = true;
            accLPC.accountCreated=true;
            accLPC.query=testQuery1;
            accLPC.runQuery();
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('Search term must be more than two Characters'));
        }
        
        
        //for runQuery  else condition
        try
        {
            accLPC.accountCreated=false;
            accLPC.runQuery();
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('Search term must be more than two Characters'));
        }
        
        accLPC.createNew();
        accLPC.accountCreated= true;
        accLPC.redirectPage();
        
    }
    
    
}
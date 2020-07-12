@isTest
private class AssociateEventMultipleOppsControllerTest {
    private static Account a;
    private static Account a1;
    private static List<Event> eventList;
    private static UserRole r = new UserRole(DeveloperName = 'newdevuser', Name = 'MyneRole');
    private static User u;
    private static Opportunity objOppty;
    private static eventRelation er;
    private static Contact c;
    
    //Test the Save Method
    @isTest
    private static void testAssociateEventMultipleOppsController()
    {
      
        insert r;
        u = testUtils.createUser('lname', 'new@gmaibl.com', r.id, true);
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AssociateEventToMultipleProposals;
        //In this case, the Visualforce page named 'AssociateEventToMultipleProposals' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        System.runAs(u)
        {
            test();
            //passing parameter to url
	        ApexPages.currentPage().getParameters().put('EventId',eventList.get(0).Id);
	         
	        //Instantiate and construct the controller class. 
	        AssociateEventMultipleOppsController assEMOC = new AssociateEventMultipleOppsController();
	        
	        //Intialising the Wrapperlist
	        List<AssociateEventMultipleOppsController.PledgeOpportunityWrapper> pList = new List<AssociateEventMultipleOppsController.PledgeOpportunityWrapper>();
	        AssociateEventMultipleOppsController.PledgeOpportunityWrapper oppWrapperInsert = new AssociateEventMultipleOppsController.PledgeOpportunityWrapper(true,objOppty);
	        pList.add(oppWrapperInsert);
	        assEMOC.opptyWrapper = pList;
	                
	        Test.startTest();
	            assEMOC.save();
	        Test.stopTest();
	        
	        system.assertEquals(3,[SELECT count() FROM Event ]);
	        
	        //call Cancel
	        assEMOC.Cancel();
	        
	        delete [SELECT Id FROM Opportunity];
            AssociateEventMultipleOppsController assEMOC1 = new AssociateEventMultipleOppsController();
            system.assertEquals(1, assEMOC.opptyWrapper.size());
        }                
    }
    
    //Create Test records
    private static void test(){
        eventList = new List<Event>();
        //Create Accounts
        a = testUtils.createAccount('newAccount', true);
        a1 = testUtils.createAccount('newtest',true);
        
        //Create Contacts
        c = testUtils.createContact(a,'fname','lName', false);
        c.Email = 'test@gmail.com';
        insert c;
        
        //Create Opportunity
        objOppty = testUtils.createOpportunity(a1.id,'oppNew',false);
        objOppty.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        insert objOppty;
        
        //creating parentEventRec
        Event eParent = TestUtils.createEvent('test subject', a1.Id, c.Id, System.today(), datetime.newInstance(2017, 9, 15, 13, 30, 0), false);
        eParent.DurationInMinutes = 1440;
        eventList.add(eParent);
      

        Event eParent1 = TestUtils.createEvent('test subject', a1.Id, c.Id, System.today(), datetime.newInstance(2017, 9, 15, 13, 30, 0), false);
        eParent1.DurationInMinutes = 1440;
        eventList.add(eParent1);
        
        insert eventList;
        
        
        eventList.get(1).Parent_Task_Id__c = String.ValueOf(eventList.get(0).Id).substring(0,15);
     	eventList.get(1).WhatId = objOppty.id;
        
    }
    
    //Method to throw error when records are not selected
    @isTest
    private static void testAssociateEventMultipleOppsController2()
    {
        insert r;
        u = testUtils.createUser('lname', 'new@gmaibl.com', r.id, true);
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AssociateEventToMultipleProposals;
        //In this case, the Visualforce page named 'AssociateEventToMultipleProposals' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        System.runAs(u)
        {
            test();
        }
        
        //passing parameter to url
        ApexPages.currentPage().getParameters().put('EventId',eventList.get(0).Id);
        
        //Instantiate and construct the controller class. 
        AssociateEventMultipleOppsController assEMOC = new AssociateEventMultipleOppsController();
      
        assEMOC.save();
        system.assertEquals(1, assEMOC.opptyWrapper.size());
    }  
    
    //Method to test the existing events for a Opportunity
    @isTest
    private static void testAssociateEventMultipleOppsController3(){
        insert r;
        u = testUtils.createUser('lname', 'new@gmaibl.com', r.id, true);
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AssociateEventToMultipleProposals;
        //In this case, the Visualforce page named 'AssociateEventToMultipleProposals' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        //Create TestData
        System.runAs(u)
        {
            test();
            //update the Event record fields with the parent Id;
	        eventList.get(1).Parent_Task_Id__c = String.ValueOf(eventList.get(0).Id).substring(0,15);
	        eventList.get(1).WhatId = objOppty.id;
	        update eventList.get(1);
        }
        
        //passing parameter to url
        ApexPages.currentPage().getParameters().put('EventId',eventList.get(0).Id);
        
        //Instantiate and construct the controller class. 
        AssociateEventMultipleOppsController assEMOC = new AssociateEventMultipleOppsController();
        system.assertEquals(1, assEMOC.opptyWrapper.size());
    }
}
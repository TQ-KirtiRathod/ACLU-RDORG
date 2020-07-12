/*
*
*Name  :  PortfolioDashboardControllerTest 
*Author:  Appirio : Shobhit Pant
*Date  :  June 19, 2017
*Purpose : Test Class for PortfolioDashboardController
*/
@isTest
public class PortfolioDashboardControllerTest {
    
    @isTest
    static void testPortfolioDashboardController(){
        Confidential_Data__c cfd = [SELECT Completed_By__c FROM Confidential_Data__c LIMIT 1];
        
        Test.startTest();
        //setting PortfolioDashboard as current page
        Test.setCurrentPage(Page.PortfolioDashboard);
        //controller constructor call
        PortfolioDashboardController controllerObj = new PortfolioDashboardController();
        //providing values to controller variables
        controllerObj.selectedFiscalYear = '2018';
        controllerObj.selectedTeamRole = 'Solicitor';
        controllerObj.selectedAffiliate = 'NN';
        controllerObj.confidentialData = cfd;
        //other controller methods
        controllerObj.getPrimaryAffiliate();
        controllerObj.getTeamRoles();
        controllerObj.getYearOptions();
        controllerObj.showReport();
        system.assert(controllerObj.mapTypeOfAmountWithTotalAmount.keySet().size() > 0);
        Test.stopTest();
    }
    
    @isTest
    static void testPortfolioDashboardControllerWithParams(){
        Portfolio__c portfolio = [SELECT Name, Affiliate__c FROM Portfolio__c];
        
        Test.startTest();
        //setting PortfolioDashboard as current page
        PageReference pRef = Page.PortfolioDashboard;
        pRef.getParameters().put('portfolioID', portfolio.Id);
        pRef.getParameters().put('fy', 'all');
        Test.setCurrentPage(pRef);
        //controller constructor call
        PortfolioDashboardController controllerObj = new PortfolioDashboardController();
        //other controller methods
        controllerObj.showReport();
        system.assertEquals(1600.0, controllerObj.totalPortClosedAmount);
        Test.stopTest();
    }
    
    @testSetup // Method to create test data
    static  void createData(){
        //opportunity and oppourtunityteammember list
        List<Opportunity> oppList = new List<Opportunity>();
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
        
        //random user Id (required to pass with confidential data)
        Id userId = UserInfo.getUserId();
        
        Account acc = TestUtils.createAccount('Test Account', true);
        Contact objContact = TestUtils.createContact(acc, 'Test', 'Contact', true);
        
        //creating confidential data without testUtils - no required fields, userid as controller variable
        Confidential_Data__c cfd = new Confidential_Data__c(Account__c = acc.Id, Completed_By__c = userId);
        insert cfd;
        
        Portfolio__c port = TestUtils.createPortfolio('Test Port', false);
        port.Affiliate__c='NN';
        insert port;
        
        
        //creating 16 opportunities (1 for each stagename)
        for(integer i = 0 ; i < 16 ; i++){
            Opportunity opp = TestUtils.createOpportunity(acc.Id , 'testOpportunity' , false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
            opp.rC_Giving__Requested_Amount__c = 1000;
            opp.rC_Giving__Expected_Giving_Amount__c = 200;
            opp.rC_Giving__Closed_Amount__c = 100;
            opp.Closed_Amount_Payments__c = 0;
            opp.Portfolio__c = port.id;
            //opp.Fiscal_Year__c = '2018';
            opp.CloseDate = System.today();
            oppList.add(opp);
            
        }
        //changing stagename for every opportunity from list (StageName - prospect is provided at TestUtils.createOpportunity by default)
        if(oppList.size()>0){
            oppList.get(0).StageName = '01. Identify';
            oppList.get(1).StageName = '01.1 Qualify';
            oppList.get(2).StageName = '02. Strategy/In Progress';
            oppList.get(3).StageName = '02.1 No Progress';
            oppList.get(4).StageName = '02.5 Cultivation';
            oppList.get(5).StageName = '03. Solicitation';
            oppList.get(6).StageName = '04. Negotiation';
            oppList.get(7).StageName = '05. Verbal Pledge';
            oppList.get(8).StageName = '05.1 Written Pledge';
            oppList.get(9).StageName = '06. Made Gift';
            oppList.get(10).StageName = '06.1 Stewardship';
            oppList.get(11).StageName = '07. Rejected';
            oppList.get(12).StageName = '08. Deferred';
            oppList.get(13).StageName = '09. Cancelled';
            oppList.get(14).StageName = '09.1 Closed';
            oppList.get(15).StageName = '10. Complete';
            insert oppList;
        }
        
        for(Integer i = 0; i <16 ; i++){
            //creating opportunity team member
            OpportunityTeamMember otm = TestUtils.createOpportunityTeamMember(userId , oppList.get(i).Id , false);
            //random TeamMemberRole not important
            otm.TeamMemberRole = 'Solicitor';
            otm.Contact__c = objContact.Id;
            otmList.add(otm);
        }
        insert otmList;
    }
}
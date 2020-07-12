@isTest
private class PopulateRevenueTypeTest {
    
    @isTest //Method to test working of PopulateRevenueType
    static void testMethod1(){
        List<opportunity> oppList = [SELECT Name, CloseDate, StageName, rC_Giving__Source_Code__c, 
                                            RPT_Package_Code__c, Sharing_Code__c, Program_Type__c, Deposit_Site__c
                                     FROM Opportunity];
        Test.startTest();
        List<opportunity> getOppList = PopulateRevenueType.populateRevenueType(oppList);
        
        for(Opportunity o: getOppList){
            if(o.rC_Giving__Source_Code__c =='5675675SF'){
                System.assertEquals('Short Fall', o.RPT_Revenue_Type__c);
            }
        }
        Test.stopTest();
    }
    
    @testSetup // Method to create test data
    static void setup() {
        List<opportunity> oppList = new List<Opportunity>();
        for(Integer i=0;i<5;i++){
            Opportunity opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.rC_Giving__Source_Code__c='5675675SF';
            opp.StageName = 'Completed';
            oppList.add(opp);

            opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.RPT_Package_Code__c='123CPXX';
            opp.StageName = 'Completed';
            oppList.add(opp);

            opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.RPT_Package_Code__c='123CPCC';
            opp.StageName = 'Completed';
            oppList.add(opp);

            opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.Program_Type__c='1';
            opp.Sharing_Code__c='A001';
            opp.StageName = 'Completed';
            oppList.add(opp);

            opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.Sharing_Code__c='Q001';
            opp.StageName = 'Completed';
            oppList.add(opp);

            opp = TestUtils.createOpportunity(null, 'Test'+i, false);
            opp.StageName = 'Completed';
            oppList.add(opp);
        }
        insert oppList;
    }
}
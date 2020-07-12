/**
 * Test Class for BatchUpdateStatusOnOpportunity
 **/
@isTest
public class BatchUpdateStatusOnOpportunityTest {
    @isTest
    public static void testBatchUpdate(){
       
       Set<id> oppId = new Set<id>();
       List<Opportunity> oppList = new List<Opportunity>();
       Account a = testUtils.createAccount('test acc', true);
       String preAff = 'test';
        
       for(integer i=0;i<10;i++)
       {
           Opportunity opp = testUtils.createOpportunity(a.id, 'opp'+i, false);
           opp.Acknowledgment_Status__c = 'N - Not Acknowledged';
           opp.StageName = 'Completed';
           opp.Acknowledgment_Code__c = 'te st hello';
           opp.rC_Giving__Acknowledged_Date__c = null;
           oppList.add(opp);
       }
       upsert oppList;
        
        for (Integer i=0; i<5; i++) {
            oppId.add(oppList[i].Id);
        }
       Test.startTest();
       BatchUpdateStatusOnOpportunity obj = new BatchUpdateStatusOnOpportunity(oppId,preAff);
       DataBase.executeBatch(obj);
       Test.stopTest();
        
       System.assertEquals('N - Not Acknowledged',oppList.get(1).Acknowledgment_Status__c);
       System.assertEquals('N - Not Acknowledged',oppList.get(9).Acknowledgment_Status__c);
    }
}
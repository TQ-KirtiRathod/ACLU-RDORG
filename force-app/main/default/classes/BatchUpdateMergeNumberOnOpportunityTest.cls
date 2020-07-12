@isTest
public class BatchUpdateMergeNumberOnOpportunityTest {
    
    @isTest //Method to test BatchUpdate MergeNumber On Opportunity
    public static void testBatchUpdateMergeNumberOnOpportunity(){
        Set<id> oppIdSet = new Set<id>();
        for(Opportunity opp : [SELECT Id, Merge_Job_Number__c FROM Opportunity]) {
            oppIdSet.add(opp.id);   
        }
        
        Test.startTest();
        BatchUpdateMergeNumberOnOpportunity obj = new BatchUpdateMergeNumberOnOpportunity('12',oppIdSet,true,'test');
        DataBase.executeBatch(obj);
        Test.stopTest();
        
        //opp given new merge number changed from 10 to 12 after batch executes
        System.assertEquals('12', [SELECT Id, Merge_Job_Number__c 
                                   FROM Opportunity
                                   WHERE Id IN :oppIdSet].get(0).Merge_Job_Number__c);
        System.assertEquals('test', obj.primaryAffiliate);
    }
    
    @testSetup //Method to create Test Data
    static void createTestData() {  
        List<Opportunity> oppList = new List<Opportunity>();
        Account acc = testUtils.createAccount('test acc', true);
        
        for(integer i=0;i<10;i++)
        {
            Opportunity opp = testUtils.createOpportunity(acc.id, 'opp'+i, false);
            opp.Merge_Job_Number__c = '10';
            oppList.add(opp);
        }
        upsert oppList;
    }
}
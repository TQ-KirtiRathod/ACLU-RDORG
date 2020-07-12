/** 
 * Test Class for CampaignRollUpBatch
 **/
@isTest
private without sharing  class CampaignRollUpBatchTest {
    public static List<Account> listAccount; 
    public static List<Opportunity> listOpportunity;
    public static List<Opportunity_Start_End_Date_To_Process__c> listStartEndToDate;
    public static  Map<String,Schema.RecordTypeInfo> optRecord;
    @isTest
    private static void testCampaignRollUpBatch(){
        createData();
        Test.startTest();
        CampaignRollupBatch cmRB = new CampaignRollupBatch();
        Database.executebatch(cmRB);
        Test.stopTest();
        CampaignRollUpBatch.setCFYdollars(String.valueOf(Date.today().year()), 10);
        CampaignRollUpBatch.setCFYdollars(String.valueOf((Date.today()+365).year()), 10);
        cmRB.getFiscalYear(Date.newInstance(23,03,2017));
        list<Campaign_Roll_Up__c> campRollUpList = [SELECT Id, Outstanding_Pledges__c, CFY_Cash_To_Date__c 
                                                        FROM Campaign_Roll_Up__c];
        system.assertEquals(campRollUpList.size(), 2);
        for(Campaign_Roll_Up__c c : campRollUpList) {
            system.assertEquals(c.Outstanding_Pledges__c, 3003.0);
            system.assertEquals(c.CFY_Cash_To_Date__c, 3012.0);
        }
    } 
    private static void createData(){
        listOpportunity=new List<Opportunity>();
        listAccount=new List<Account>();
        id OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
        id OPPORTUNITY_RT_TRANSACTION_Id;
        id OPPORTUNITY_RT_PLEDGE_Id;        
        optRecord= Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        
        listStartEndToDate= new List<Opportunity_Start_End_Date_To_Process__c>();
        Opportunity_Start_End_Date_To_Process__c oppc= TestUtils.createOpptyStartEndProcess('CloseDate', Date.today(), Date.today()+5, false);
        listStartEndToDate.add(oppc);
        
        Opportunity_Start_End_Date_To_Process__c oppc1 = TestUtils.createOpptyStartEndProcess('Tax_Date__c', Date.today(), Date.today()+6, false);
        listStartEndToDate.add(oppc1);
        
        Opportunity_Start_End_Date_To_Process__c oppc2 = TestUtils.createOpptyStartEndProcess('Run Range', Date.today(), Date.today()+7, false);
        listStartEndToDate.add(oppc2);
        
        Opportunity_Start_End_Date_To_Process__c oppc3 = TestUtils.createOpptyStartEndProcess('rC_Giving__Contract_Date__c', Date.today(), Date.today()+7, false);
        listStartEndToDate.add(oppc3);
        
        insert listStartEndToDate;
        
        for(Integer i=0;i<10;i++){
            Account acc= TestUtils.createAccount('Test'+i, false);
            listAccount.add(acc);
        }
        insert listAccount;
        
        String oppPledgeRecType = optRecord.get('Pledge').getRecordTypeId();
        String oppPledgePaymentRecType = optRecord.get('Pledge Payment').getRecordTypeId();
        for(Integer i=0;i<3;i++){
            Opportunity opp = TestUtils.createOpportunity(listAccount[i].Id, 'test'+i, false);
            opp.RecordTypeId=oppPledgeRecType;
            opp.rC_Giving__Pipeline_Amount__c=1000+i;
            opp.RPT_Revenue_Type__c = 'TRANSFORMATIONAL';
            opp.Sharing_Code__c='test';
            opp.rC_Giving__Is_Bookable__c=True;
            opp.Sharing_Entity__c='NA - At-Large National Office ACLU';
            opp.Account_Affiliation__c='te';
            opp.Tax_Date__c=Date.today()+1;
            opp.CloseDate=Date.today()+1;
            opp.StageName='Prospecting';
            opp.AccountId=listAccount.get(i).id;       
            opp.Adjustment_Code__c = 'D';
            opp.StageName='Completed';
            listOpportunity.add(opp);
        }
           for(Integer i=3;i<6;i++){
            Opportunity opp = TestUtils.createOpportunity(listAccount[i].Id, 'test'+i, false);
            opp.RecordTypeId=oppPledgePaymentRecType;
            opp.CloseDate=Date.today()+1;
            opp.StageName='Prospecting';  
            opp.RPT_Revenue_Type__c = 'TRANSFORMATIONAL';
            opp.Amount=1000+i; 
            opp.Sharing_Entity__c='NA - At-Large National Office ACLU';
            opp.Account_Affiliation__c='te';
            opp.rC_Giving__Pipeline_Amount__c=1000+i;   
            opp.Sharing_Code__c='test';  
            opp.rC_Giving__Is_Bookable__c=True;   
            opp.AccountId=listAccount.get(i).id;  
            opp.Adjustment_Code__c = 'D';
            opp.StageName='Completed';
            listOpportunity.add(opp);
        }
        insert listOpportunity;
    }
}
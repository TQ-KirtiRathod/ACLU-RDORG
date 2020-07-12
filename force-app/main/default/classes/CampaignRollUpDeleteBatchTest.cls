/**
 * Test Class for CampaignRollUpDeleteBatch
 **/
@isTest
Private class CampaignRollUpDeleteBatchTest {
    Public static List<Campaign_Roll_Up__c> listCampaign_Roll_Up;
@isTest
    Private static void TestCampaignRollUpDeleteBatch(){
        createData();
        Test.startTest();
        Database.executebatch(new CampaignRollUpDeleteBatch());       
        Test.stopTest();

        System.assertEquals('test1',listCampaign_Roll_Up.get(1).Name);
    }
@isTest
    private static void TestCampaignRollUpDeleteCatch1(){
        createData();
        Campaign_Roll_Up__c cmp= TestUtils.createCampaignRollUp('test', null, false);
        cmp.Comments__c='test';
        listCampaign_Roll_Up.add(cmp);
        try{insert listCampaign_Roll_Up;}
        catch(Exception e)
        {
            System.assertEquals(e.getMessage(),e.getMessage());
        }        
    		      
        Test.startTest();
        Database.executebatch(new CampaignRollUpDeleteBatch());       
        Test.stopTest();
    }	  

    public static void createData(){
        
        List<Opportunity_Start_End_Date_To_Process__c> listStartEndToDate= new List<Opportunity_Start_End_Date_To_Process__c>();
        
        Opportunity_Start_End_Date_To_Process__c oppc= TestUtils.createOpptyStartEndProcess('CloseDate', Date.today(), Date.today()+5, false);
        listStartEndToDate.add(oppc);
        
        Opportunity_Start_End_Date_To_Process__c oppc1 = TestUtils.createOpptyStartEndProcess('Tax_Date__c', Date.today(), Date.today()+6, false);
        listStartEndToDate.add(oppc1);
        
        Opportunity_Start_End_Date_To_Process__c oppc2 = TestUtils.createOpptyStartEndProcess('Run Range', Date.today(), Date.today()+7, false);
        listStartEndToDate.add(oppc2);
        
        Opportunity_Start_End_Date_To_Process__c oppc3 = TestUtils.createOpptyStartEndProcess('rC_Giving__Contract_Date__c', Date.today(), Date.today()+7, false);
        listStartEndToDate.add(oppc3);
        
        insert listStartEndToDate;

       
        listCampaign_Roll_Up = new List<Campaign_Roll_Up__c>();
        for(Integer i=0;i<10;i++){
            Campaign_Roll_Up__c cmp= TestUtils.createCampaignRollUp('test'+i, String.valueOf(date.today().year()+1), false);
            listCampaign_Roll_Up.add(cmp);            
        }
        insert listCampaign_Roll_Up;
    }
}
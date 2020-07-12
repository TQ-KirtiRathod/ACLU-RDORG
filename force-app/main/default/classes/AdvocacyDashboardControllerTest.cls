@isTest
public class AdvocacyDashboardControllerTest {
    
   /* @isTest
    public static void testAdvocacyDashboardController1(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AdvocacyDashboard;
        //In this case, the Visualforce page named 'AdvocacyDashboard' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        //creating custom settings record
        Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c();
        lstRT.name = 'BatchProcessOnEmail';
        lstRT.Last_Run_Time__c = Date.newInstance(2011,11,11);
        insert lstRT;
        
        //creating custom settings record
        Last_Run_Time_Of_Batch__c lstRT2 = new Last_Run_Time_Of_Batch__c();
        lstRT2.name = 'BatchProcessOnGiving';
        lstRT2.Last_Run_Time__c = Date.newInstance(2013,11,31);
        insert lstRT2;
        
        //creating custom settings record
        Last_Run_Time_Of_Batch__c lstRT3 = new Last_Run_Time_Of_Batch__c();
        lstRT3.name = 'BatchOnActionTaken';
        lstRT3.Last_Run_Time__c = Date.newInstance(2012,11,12);
        insert lstRT3;
        
        AdvocacyDashboardController adc = new AdvocacyDashboardController();
        
        
        List<AdvocacyDashboardController.PieWedgeData> pList = new List<AdvocacyDashboardController.PieWedgeData>();
        AdvocacyDashboardController.PieWedgeData oppWrapperInsert = new AdvocacyDashboardController.PieWedgeData('test',12);
        pList.add(oppWrapperInsert);
        adc.lstPieData = pList;
        
        List<AdvocacyDashboardController.PieWedgeData> pList1 = new List<AdvocacyDashboardController.PieWedgeData>();
        AdvocacyDashboardController.PieWedgeData oppWrapperInsert1 = new AdvocacyDashboardController.PieWedgeData('email',12);
        pList1.add(oppWrapperInsert1);
        adc.mktScByEmailPieData = pList1;
        
        List<AdvocacyDashboardController.PieWedgeData> pList2 = new List<AdvocacyDashboardController.PieWedgeData>();
        AdvocacyDashboardController.PieWedgeData oppWrapperInsert2 = new AdvocacyDashboardController.PieWedgeData('email',12);
        pList2.add(oppWrapperInsert2);
        adc.mktScByActionsPieData = pList2;
        
        Campaign c = testUtils.createCampaign('test camp', false);
        c.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert c;
        
        sb_action__c s = new sb_action__c();
        s.name = 'test action';
        s.Springboard_ID__c = 11;
        s.Campaign__c = c.id;
        insert s;
        
        adc.actionData = s;
        adc.showReport();
        
    }
    
    
    @isTest
    public static void testAdvocacyDashboardController2()
    {
        
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AdvocacyDashboard;
        //In this case, the Visualforce page named 'AdvocacyDashboard' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        //creating custom settings record
        Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c();
        lstRT.name = 'BatchProcessOnEmail2';
        lstRT.Last_Run_Time__c = Date.newInstance(2013,11,31);
        insert lstRT;
        
        AdvocacyDashboardController adc = new AdvocacyDashboardController();
        Campaign c = testUtils.createCampaign('test camp', false);
        c.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert c;
        sb_action__c s = new sb_action__c();
        s.name = 'test action';
        insert s;
        adc.actionData = s;
        adc.showReport();
        
    }*/
    
    
    @isTest
    public static void testAdvocacyDashboardController3()
    {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.AdvocacyDashboard;
        //In this case, the Visualforce page named 'AdvocacyDashboard' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        
        //creating custom settings record
        Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c();
        lstRT.name = 'BatchProcessOnEmail';
        lstRT.Last_Run_Time__c = Date.newInstance(2011,11,11);
        insert lstRT;
        
        AdvocacyDashboardController adc = new AdvocacyDashboardController();
        adc.campaignGroupId = null;
        adc.campaignId = null;
        Report r = new Report();
        adc.actionTakenOverTime = r.id;
        adc.actionTakenByContact = r.id;
        
        Campaign c = testUtils.createCampaign('test camp', false);
        c.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert c;
        sb_action__c s = new sb_action__c();
        s.name = 'test action';
        s.Springboard_ID__c = 121;
        insert s;
        adc.actionData = s;
        adc.showReport();
        
        sb_action__c s1 = new sb_action__c();
        s1.name = 'test 11 action';
        s1.Campaign__c = c.id;
        insert s1;
        adc.actionData = s1;
        adc.showReport();
        
        Campaign_Grouping__c cg = new Campaign_Grouping__c();
        cg.Name = 'test cg';
        insert cg;
        sb_action__c s2 = new sb_action__c();
        s2.name = 'test 1 action';
        s2.Campaign_Grouping__c = cg.id;
        insert s2;
        adc.actionData = s2;
        adc.showReport();
        
        System.assertEquals(null, [SELECT Actions_Taken_by_New_Email__c,name FROM sb_action__c WHERE name =:'test 1 action'].get(0).Actions_Taken_by_New_Email__c);
        System.assertEquals(true, (String.isNotBlank(String.valueOf([SELECT Campaign_Grouping__c,name FROM sb_action__c WHERE name =:'test 1 action'].get(0).Campaign_Grouping__c))));
        System.assertEquals(true, (String.isNotBlank(String.valueOf([SELECT Campaign__c,name FROM sb_action__c WHERE name =:'test 11 action'].get(0).Campaign__c))));
        
        
    }
    
}
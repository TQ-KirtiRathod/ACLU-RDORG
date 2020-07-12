/*
*
*Name  :  CampaignMemberTriggerHandlerTest
*Author:  Appirio India (Sakshi Arora)
*Date  :  May 26,2017
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
public class CampaignMemberTriggerHandlerTest {
    private static List<Lead> leads;
    private static List<Campaign> listCampaign;
    private static List<CampaignMember> listCampMember;
    
	/*
	*
	* Method campMemberDataTest
	* Testing before insert scenarios
	*/
    static testMethod void campMemberBeforeInsertTest() {
        
        listCampMember = new List<CampaignMember>(); 
        listCampaign = new List<Campaign>();
        leads = new List<Lead>();
        setup();
        
        Test.startTest();
        	insert listCampMember;
        Test.stopTest();
        
        List<Lead> lead = [SELECT Id, LeadSource, SB_Donation_Id__c, Meal_Preference__c, Giving_Id__c FROM Lead WHERE Id =: leads[0].Id];
        List<CampaignMember> cmpgMember = [SELECT Id, Meal_Preference__c, Opportunity__c FROM CampaignMember WHERE ID =: listCampMember[0].Id];
        
        System.assertEquals(lead[0].Meal_Preference__c, cmpgMember[0].Meal_Preference__c);
        System.assertEquals(lead[0].Giving_Id__c, cmpgMember[0].Opportunity__c);
        
    }
    
    /*
	*
	* Method setup
	* To Create Test Data
	*/
    private static void setup(){
        
        Account acc = TestUtils.createAccount('TestAccount'+1,true);
        Opportunity opp = TestUtils.createOpportunity(acc.Id,'Test Opportunity'+1 , true);
        Lead ld;
        Campaign camp;
        CampaignMember cm1;
        
        // Insert Lead Records
        for(Integer i=0;i<5;i++){   
            ld = TestUtils.createLead('Lead'+i,'comapanytest','open',false);
            ld.LeadSource = 'Springboard';
            ld.SB_Donation_Id__c = opp.Id;
            ld.Meal_Preference__c = 'Test Meal';
            ld.Giving_Id__c = opp.Id;
            leads.add(ld);
        }  
        insert leads;
        
        // Insert Campaign Records 
        for(Integer i=0;i<5;i++){
            camp = TestUtils.createCampaign('TestCampaign'+1,false);
            camp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
            listCampaign.add(camp);
            
        }
        insert listCampaign;
        
        // Campaign member data Records
        for(Integer j=0;j<5;j++){
            cm1 = TestUtils.createCampaignMember(listCampaign[j].Id,leads[0].Id,false); 
            cm1.rC_Event__Registered_Date__c = system.today();
            cm1.rC_Event__Attendance_Status__c = 'Pending';
            cm1.Status = 'Sent';
            cm1.rC_Event__Registered_Status__c = 'Registered';
            cm1.rC_Event__Registered_Count__c = 1;
            cm1.leadId = leads[j].id;
            listCampMember.add(cm1);
        }
    }
}
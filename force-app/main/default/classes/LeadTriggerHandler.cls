/*
*
*Name  :  LeadTriggerHandler
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  May 12, 2017
*Purpose : Handler Class for LeadTrigger. Logic includes adding Campaign Members
*
*/
public class LeadTriggerHandler {
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */ 
    public static void mainEntry(List<Lead> newList, List<Lead> oldList, Map<Id, Lead> newMap, Map<Id, Lead> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('LeadTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            // It is called on after insert
            if(isAfter) {
                if(isInsert) {
                  onAfterInsert(newList);
                } 
            }
        }
    }
    
    public static void onAfterInsert(List<Lead> newList) {
      List<CampaignMember> listOfCampaignMembers = new List<CampaignMember>();
      for(Lead theLead : newList) {
        if(theLead.SB_Campaign_Id__c != null && (theLead.SB_Campaign_Id__c.length() >= 15) && theLead.SB_Campaign_Id__c.startsWith('701')) {
          listOfCampaignMembers.add(new CampaignMember(CampaignId = theLead.SB_Campaign_Id__c, LeadId = theLead.Id));
        }    
      }
      try {
        if(!listOfCampaignMembers.isEmpty()) {
        insert listOfCampaignMembers;
        }
      }
      catch(Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('LeadTriggerHandler','onAfterInsert',e.getMessage());
        log.logException(e);
        log.saveLogs();  
      }
      /*system.debug('Entered in Trigger');
      list<Lead> eventTransactionLeads = new list<Lead>();
      for(Lead ld : newList) {
        if(!String.isBlank(ld.SB_Donation_Id__c)) {
          system.debug('*********'+ld.SB_Donation_Id__c);
          eventTransactionLeads.add(ld);
        }
      }
      if(!eventTransactionLeads.isEmpty()) {
        createCampaignMembersForLeads(eventTransactionLeads);
      }
      system.debug('Exit from Trigger');*/
    }
    
    /*public static void createCampaignMembersForLeads(List<Lead> leadList) {
        system.debug('Entered in Method');
        list<CampaignMember> campaignMemList = new list<CampaignMember>();
        CampaignMember cm;
        for(Lead ld : leadList) {
            cm = new CampaignMember();
            cm.Status = 'Sent';
            cm.rC_Event__Registered_Status__c = 'Paid';
            cm.LeadId = ld.Id;
            cm.rC_Event__Registered_Count__c = 1;
            cm.rC_Event__Registered_Date__c = system.today();
            cm.rC_Event__Attendance_Status__c = 'Pending';
            cm.Meal_Preference__c = ld.Meal_Preference__c;
            cm.Opportunity__c = ld.Giving_Id__c;
            //cm.CampaignId = ld.CampaignId;
            //cm.FirstName = ld.FirstName;
            //cm.Lastname = ld.LastName;
            campaignMemList.add(cm);
        }
        if(!campaignMemList.isEmpty()) {
            try{
                insert campaignMemList;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('LeadTriggerHandler','createCampaignMembersForLeads',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }*/
}
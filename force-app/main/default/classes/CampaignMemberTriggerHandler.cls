/*
*
*Name  :  CampaignMemberTriggerHandler 
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  May 16, 2017
*Purpose : Handler Class for CampaignMemberTrigger(T-585153). Logic includes Before Insert data enrichment
*/
public class CampaignMemberTriggerHandler {
    public static void mainEntry(List<CampaignMember> newList, List<CampaignMember> oldList, Map<Id, CampaignMember> newMap, Map<Id, CampaignMember> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('CampaignMemberTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            // It is called on after insert
            if(isBefore) {
                if(isInsert) {
                   onBeforeInsert(newList);
                } 
            }
        }
    }
    
    public static void onBeforeInsert(List<CampaignMember> newList) {
        list<CampaignMember> campaignMemberList = new list<CampaignMember>();
        set<Id> leadIdSet = new set<Id>();
        for(CampaignMember cm : newList) {
            if(!String.isBlank(cm.leadId)) {
                campaignMemberList.add(cm);
                leadIdSet.add(cm.leadId);
            }
        }
        if(!campaignMemberList.isEmpty()) {
            populateLeadFieldsOnCampaignMember(campaignMemberList, leadIdSet);
        }
    }
    
    public static void populateLeadFieldsOnCampaignMember(List<CampaignMember> campaignMemberList, set<Id> leadIdSet) {
        map<Id, Lead> leadsMap = new map<Id, Lead>([SELECT Id, LeadSource, SB_Donation_Id__c, Meal_Preference__c, Giving_Id__c
                                                        FROM Lead 
                                                        WHERE Id IN :leadIdSet]);
        //Id recTypeId = Schema.SObjectType.CampaignMember.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        for(CampaignMember cm : campaignMemberList) {
            if(leadsMap.get(cm.leadId).LeadSource == 'Springboard' && leadsMap.get(cm.leadId).SB_Donation_Id__c != null) {
                //cm.RecordTypeId = recTypeId;
                cm.Status = 'Sent';
                cm.rC_Event__Registered_Status__c = 'Registered';
                //cm.LeadId = ld.Id;
                cm.rC_Event__Registered_Count__c = 1;
                cm.rC_Event__Registered_Date__c = system.today();
                cm.rC_Event__Attendance_Status__c = 'Pending';
                cm.Meal_Preference__c = leadsMap.get(cm.leadId).Meal_Preference__c;
                cm.Opportunity__c = leadsMap.get(cm.leadId).Giving_Id__c;
            } 
        }
    }
}
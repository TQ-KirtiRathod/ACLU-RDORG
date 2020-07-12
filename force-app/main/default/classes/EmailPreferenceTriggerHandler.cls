/*
*
*Name  :  EmailPreferenceTriggerHandler
*Author:  ACLU  (David Reed)
*Date  :  Sept 05, 2017
*Purpose : Handler class for EmailPreferenceTrigger for op in management
*
*/
public class EmailPreferenceTriggerHandler {
    public static void mainEntry(List<Email_Preference__c> newList, 
                                 List<Email_Preference__c> oldList, 
                                 Map<Id,Email_Preference__c> newMap, 
                                 Map<Id,Email_Preference__c> oldMap, 
                                 Boolean isInsert, Boolean isUpdate, 
                                 Boolean isDelete, Boolean isUndelete, 
                                 Boolean isBefore, Boolean isAfter) {

        if(TriggerState.isActive('Email_Preference_Trigger') 
            && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) 
            && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {
            // It is called on before insert
            if(isBefore) {
                if(isInsert) {
                    beforeInsert(newList);

                }
            }

            if(isBefore) {
                if(isUpdate) {
                    beforeUpdate(newList, oldMap);
                }
            }
        }
    }

    public static void beforeUpdate(List<Email_Preference__c> newEPs, Map<Id, Email_Preference__c> oldMap) {
        for (Email_Preference__c ep : newEPs) {
            if (ep.opt_In__c != oldMap.get(ep.Id).opt_In__c) {
                // Ignore changes that are made by the opt-out processor.
                if (!EmailOptOutProcessor.isEmailPreferenceInScope(ep.Id)) {
                    ep.Opt_In_Status_Changed__c = true;
                }
            }
            setOptOutDate(ep, oldMap.get(ep.Id));  
        }
    }
    
    public static void beforeInsert(List<Email_Preference__c> newEPs) {
        for (Email_Preference__c ep : newEPs) {
            ep.Opt_In_Status_Changed__c = true;
        }
    }
    
    /*
	* Method setOptOutDate
	* Per ZD-57283 
	*/
    @TestVisible private static void setOptOutDate(Email_Preference__c ep, Email_Preference__c oldEp) {
    	if (ep.Opt_In__c == FALSE && oldEp.Opt_Out_Date__c == NULL) {
            ep.Opt_Out_Date__c = Date.Today();
        }
    }
}
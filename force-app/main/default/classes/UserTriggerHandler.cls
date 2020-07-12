/*
*
*Name  :  UserTriggerHandler
*Author:  ACLU (David Reed)
*Date  :  July 27, 2017
*Purpose : Handler class for UserTrigger, checks for valid email address
*
*/
public class UserTriggerHandler {
    static Set<String> validDomains;

    static {
        validDomains = new Set<String>();
        
        for (User_Email_Whitelist__mdt uew : [SELECT Domain_Name__c FROM User_Email_Whitelist__mdt]) {
            validDomains.add(uew.Domain_Name__c);
        }
    }

    public static void mainEntry(List<User> newList, 
                                 List<User> oldList, 
                                 Map<Id, User> newMap, 
                                 Map<Id, User> oldMap, 
                                 Boolean isInsert, Boolean isUpdate, Boolean isDelete, 
                                 Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('UserTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {
            if (isBefore) {
                if(isInsert) {
                    beforeInsert(newList);
                }
                if(isUpdate) {
                    beforeUpdate(newList, oldMap);
                }

            }
        }

    }
    private static void beforeInsert(List<User> newList) {
        verifyUserEmails(newList);
    }

    private static void beforeUpdate(List<User> newList, Map<Id, User> oldMap) {
        verifyUserEmails(newList);
    }

    private static void verifyUserEmails(List<User> users) {
        for (User u : users) {
            if (String.isNotBlank(u.Email) && u.Email.contains('@')) {
                List<String> em = u.Email.split('@');

                if (em.size() != 2) {
                   // u.addError('The specified email address is not valid.');
                } else {
                    // Check the domain name for this email address.
                    String domain = em[1].trim();

                    if (!validDomains.contains(domain)) {
                       // u.addError('The specified email address is not on a domain authorized for ACLU users. Please use an ACLU or approved vendor email address.');
                    }
                }
            }
        }
    }
}
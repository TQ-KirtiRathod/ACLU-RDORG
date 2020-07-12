/*
*
*Name  :  ManageLimitsNotificationController
*Author:  Appirio India (David Reed)
*Date  :  July 07, 2017
*Purpose : Controller class for Manage_Limits_Notifications Page
*
*/
public with sharing class ManageLimitsNotificationController {
    public List<Limits_Notification__c> ls { get; private set; }
    private Map<String, List<Limits_Notification__c>> apiNameToLimitsMap;
    public String selected { get; set; }
    public String selectedName { get; set; }
    public Boolean isAdding { get; set; }
    public Id toDelete { get; set; }
    public Limits_Notification__c notificationToAdd { get; set; }
    private List<LimitWrapper> limits;

    public class LimitWrapper implements Comparable {
        public String name { get; set; }
        public Integer count { get; set; }
        public String apiName { get; set; }

        public Integer compareTo(Object compareTo) {
            if (compareTo instanceof LimitWrapper) {
                return name.compareTo(((LimitWrapper)compareTo).name);
            } 

            return 0;
        }

    }

	public ManageLimitsNotificationController() {
	}

    public List<LimitWrapper> getLimits() {
        if (limits == null) {
            Map<String, Schema.SObjectField> m = Schema.sObjectType.Limits_History__c.fields.getMap();

            ls = [SELECT Id, Limit__c, Threshold__c, Method__c, Send_To_Profile__c
                  FROM Limits_Notification__c
                  WHERE User__c = :UserInfo.getUserId()
                  ORDER BY Limit__c, Threshold__c];

            apiNameToLimitsMap = new Map<String, List<Limits_Notification__c>>();

            for (Limits_Notification__c l : ls) {
                if (apiNameToLimitsMap.containsKey(l.Limit__c)) {
                    apiNameToLimitsMap.get(l.Limit__c).add(l);
                } else {
                    apiNameToLimitsMap.put(l.Limit__c, new List<Limits_Notification__c>{ l });
                }
            }

            limits = new List<LimitWrapper>();
            Set<String> customMetadataTargetFields = new Set<String>();

            for (Limits_History_Item__mdt item: [SELECT Destination_Field__c FROM Limits_History_item__mdt]) {
                customMetadataTargetFields.add(item.Destination_Field__c);
            }

            for (String fieldName : m.keySet()) {
                String apiName = m.get(fieldName).getDescribe().getName();

                if (customMetadataTargetFields.contains(apiName) 
                    || apiName.endsWith('_M__c') 
                    || apiName.endsWith('_U__c') 
                    || apiName.endsWith('_R__c') 
                    || apiName.endsWith('_P__c')) {
                    LimitWrapper l = new LimitWrapper();

                    l.name = m.get(fieldName).getDescribe().getLabel();
                    l.apiName = apiName;
                    l.count = apiNameToLimitsMap.containsKey(apiName) ? apiNameToLimitsMap.get(apiName).size() : 0;

                    limits.add(l);
                }
            }

            limits.sort();
        }

        return limits;
    }

    public List<Limits_Notification__c> getSelectedNotifications() {
        return apiNameToLimitsMap.get(selected);
    }

    public PageReference manageNotifications() {
        // If we have a selection, we'll save all changes before switching.
        if (selected != null) {
            save();
        }
        
        return null;
    }

    public PageReference save() {
        update ls;

        return null;
    }

    public PageReference saveNewNotification() {
        try {
            insert notificationToAdd;
        } catch (Exception e) {
            return null;
        }

        isAdding = false;
        limits = null;
        notificationToAdd = null;

        return null;
    }

    public PageReference add() {
        notificationToAdd = new Limits_Notification__c(User__c = UserInfo.getUserId(), Limit__c = selected);
        isAdding = true;

        return null;
    }

    public PageReference del() {
        Limits_Notification__c n = new Limits_Notification__c(Id = toDelete);

        delete n;

        limits = null;
        ls = null;
        getLimits();

        return null;
    }
}
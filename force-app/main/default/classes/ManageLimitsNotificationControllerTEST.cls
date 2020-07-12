/*
 *
 *Name  :  ConfDataTriggerHandlerTest
 *Author:  Appirio India 
 *Date  :  May 05,2017
 *Purpose : To Test ConfDataTriggerHandler Class functionality on various trigger events
 *
 */
@isTest
private class ManageLimitsNotificationControllerTEST {
	
    //Method to create test data
    @testSetup
    static void setup() {
        List<Limits_Notification__c> lns = new List<Limits_Notification__c>{
            new Limits_Notification__c(User__c = UserInfo.getUserId(), 
                                       Limit__c = LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_U__c',
                                       Threshold__c = 0,
                                       Method__c = 'Chatter'),
            new Limits_Notification__c(User__c = UserInfo.getUserId(), 
                           Limit__c = LimitsHistoryUtilities.limitsDataKeys[1].left(34) + '_M__c',
                           Threshold__c = 0,
                           Method__c = 'Email')
        };

        insert lns;
    }

    
    //Method to compare LimitWrapper instances
	@isTest 
    static void testLimitWrapper() {
		ManageLimitsNotificationController.LimitWrapper a = new ManageLimitsNotificationController.LimitWrapper(), b = new ManageLimitsNotificationController.LimitWrapper();

        a.name = 'Test1';
        b.name = 'Test2';

        //Limit wrappers compared on the basis of names
        System.assertEquals(a.name.compareTo(b.name), a.compareTo(b));
	}
	
    
    //Mrthod to test getLimit() method of the controller
	@isTest 
    static void testGetLimits() {
        ManageLimitsNotificationController mlnc = new ManageLimitsNotificationController();
        List<ManageLimitsNotificationController.LimitWrapper> lws = mlnc.getLimits();

        System.assertEquals((LimitsHistoryUtilities.limitsDataKeys.size() * 4) + [SELECT count() FROM Limits_History_Item__mdt],
            lws.size());

        for (ManageLimitsNotificationController.LimitWrapper l : lws) {
            if (l.apiName == LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_U__c'
                || l.apiName == LimitsHistoryUtilities.limitsDataKeys[1].left(34) + '_M__c') {
                
                //Verify the count update
                System.assertEquals(1, l.count);
            } else {
                System.assertEquals(0, l.count);
            }

            //Verify the apiName update
            System.assertEquals(Schema.sObjectType.Limits_History__c.fields.getMap().get(l.apiName).getDescribe().getLabel(),
                                l.name);

        }
	}

    
    //Method to test the selection of Notifications
    @isTest
    static void testGetSelectedNotifications() {
        ManageLimitsNotificationController mlnc = new ManageLimitsNotificationController();

        mlnc.getLimits();
        mlnc.selected = LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_U__c';

        List<Limits_Notification__c> lns = mlnc.getSelectedNotifications();

        //Count of selected Notifications
        System.assertEquals(1, lns.size());
        System.assertEquals(LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_U__c', lns[0].Limit__c);
    }

    
    //Method to test the actions taken on the Notifications 
    @isTest
    static void testActions() {
        ManageLimitsNotificationController mlnc = new ManageLimitsNotificationController();

        mlnc.getLimits();

        String selected = LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_U__c';

        mlnc.selected = selected;
        mlnc.add();

        System.assert(mlnc.isAdding);
        System.assertEquals(selected, mlnc.notificationToAdd.Limit__c);

        mlnc.notificationToAdd.Method__c = 'Chatter';
        mlnc.notificationToAdd.Threshold__c = 1;

        // There's already one from the setup method.
        System.assertEquals(1, [SELECT count() 
                                FROM Limits_Notification__c
                                WHERE Limit__c = :selected]);
        mlnc.saveNewNotification();
        System.assertEquals(2, [SELECT count() 
                                FROM Limits_Notification__c
                                WHERE Limit__c = :selected]);

        Limits_Notification__c toDel = [SELECT Id FROM Limits_Notification__c LIMIT 1];

        mlnc.toDelete = toDel.Id;
		//Notification deleted
        mlnc.del();
		//Verify the count of remaining Notifications
        System.assertEquals(1, [SELECT count() FROM Limits_Notification__c WHERE Limit__c = :selected]);

        mlnc.manageNotifications();
        mlnc.save();
    }
	
}
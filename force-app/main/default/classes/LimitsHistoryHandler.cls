/*
*
*Name  :  LimitsHistoryHandler
*Author:  Appirio India (David Reed)
*Date  :  July 07, 2017
*Purpose : This class snapshots Salesforce Limits history and writes the data to the Limits_History__c object
*
*/
public class LimitsHistoryHandler {

    private class LimitsHistoryCalloutException extends Exception {}

    public static void runTasks(String context) {
        if (context == LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME) {
            // Run the hourly snapshot. 
            if (LimitsHistoryUtilities.shouldRunHourlySnapshots) {
                writeLimitsHistory(Label.Limits_History_Hourly_Snapshot_Type);
            }
        } else {
            // Perform daily tasks
            if (LimitsHistoryUtilities.shouldRunDailySnapshots) {
                writeLimitsHistory(Label.Limits_History_Daily_Snapshot_Type);
            }
            if (LimitsHistoryUtilities.shouldRotateLogs) {
                rotateLogs();
            }
        }

        selfHealHourlyJob();
        selfHealDailyJob();
    }

    public static void selfHealHourlyJob() {
        // Self-heal the hourly job if needed.
        List<CronTrigger> cts = [SELECT Id, CronExpression 
                                 FROM CronTrigger 
                                 WHERE CronJobDetail.Name = :LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME];

        if (cts.size() > 0 && (!LimitsHistoryUtilities.shouldRunHourlySnapshots
            || (cts[0].CronExpression != LimitsHistoryUtilities.hourlyCronString))) {
            // Jobs are currently scheduled, but the user has deactivated hourly snapshots;
            // or our hourly cron string has changed. Cancel the jobs.

            for (CronTrigger act : cts) {
                System.abortJob(act.Id);
            }

            cts = new List<CronTrigger>();
        }
        
        if (cts.size() == 0 && LimitsHistoryUtilities.shouldRunHourlySnapshots) {
            // No job currently scheduled, but there should be. Schedule our hourly job.

            System.schedule(LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME, 
                            LimitsHistoryUtilities.hourlyCronString, 
                            new LimitsHistoryDailySchedulable());
        }
    }

    public static void selfHealDailyJob() {
        // Make sure our daily job is always running and has the right cron expression
        List<CronTrigger> cts = [SELECT Id, CronExpression 
                                 FROM CronTrigger 
                                 WHERE CronJobDetail.Name = :LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME];

        // If we're running under the wrong cron string, end the job and restart it.
        if (cts.size() > 0 && cts[0].CronExpression != LimitsHistoryUtilities.dailyCronString) {
            for (CronTrigger act : cts) {
                System.abortJob(act.Id);
            }

            cts = new List<CronTrigger>();
        }

        if (cts.size() == 0) {
            System.schedule(LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME, 
                LimitsHistoryUtilities.dailyCronString, new LimitsHistoryDailySchedulable());
        }
    }

    @future(callout=true)
    public static void writeLimitsHistory(String snapshotType) {
        // Pull limits information using the REST API and SOQL queries, then write to a new custom object.

        Http h = new Http();
        HttpRequest r = new HttpRequest();

        r.setEndpoint('callout:Limits_Monitor/services/data/v39.0/limits');
        r.setMethod('GET');

        // All error handling is at this level (no exception handlers in generateLimitsHistory() or sendUserNotifications())
        try {
            HttpResponse res = h.send(r);
            
            if (res.getStatusCode() == 200) {
                Object data = JSON.deserializeUntyped(res.getBody());
                Limits_History__c lh;

                lh = generateLimitsHistory((Map<String, Object>)data, LimitsHistoryUtilities.limitsDataKeys, snapshotType);
                insert lh;

                sendUserNotifications(lh);
            } else {
                throw new LimitsHistoryCalloutException(res.getStatus());
            }
        } catch (Exception e) {
            if (!Test.isRunningTest()) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('LimitsHistoryHandler',
                    'writeLimitsHistory', e.getMessage());
                log.logException(e);
                log.saveLogs();
            } else {
                throw e;
            }
        }
    }

    public static Limits_History__c generateLimitsHistory(Map<String, Object> data, List<String> dataKeys, String snapshotType) {
        Limits_History__c lh = new Limits_History__c();
        
        for (String dataKey : dataKeys) {
            lh.put(dataKey.left(34) + '_M__c', (Integer)getValueByKeyPath(data, new List<String>{dataKey, 'Max'}));
            lh.put(dataKey.left(34) + '_R__c', (Integer)getValueByKeyPath(data, new List<String>{dataKey, 'Remaining'}));
        }

        // Load our custom metadata and perform a series of queries to populate additional fields.

        List<Limits_History_Item__mdt> items = [SELECT Queried_Object__c, Destination_Field__c, 
                                                       SOQL_WHERE_Clause__c
                                                FROM Limits_History_Item__mdt
                                                ORDER BY DeveloperName ASC
                                                LIMIT 99];

        for (Limits_History_Item__mdt item : items) {
            String query = 'SELECT count () FROM ' + item.Queried_Object__c + ' WHERE ' + item.SOQL_WHERE_Clause__c;

            if (Schema.sObjectType.Limits_History__c.fields.getMap().containsKey(item.Destination_Field__c)) {
                Integer ct = Database.countQuery(query);

                lh.put(item.Destination_Field__c, ct);
            }
        }

        lh.Snapshot_Type__c = snapshotType;
        lh.Snapshot_Hour__c = Datetime.now().hour();

        return lh;
    }

    public static void sendUserNotifications(Limits_History__c lh) {
        List<Messaging.SingleEmailMessage> ems = new List<Messaging.SingleEmailMessage>();
        List<FeedItem> fis = new List<FeedItem>();
        List<Limits_Notification__c> ns;
        String queryString;
        Map<Id, List<User>> profileMap = new Map<Id, List<User>>();

        ns = [SELECT User__r.Email, User__r.ProfileId, Limit__c, Threshold__c, Method__c, Send_To_Profile__c
              FROM Limits_Notification__c
              ORDER BY Limit__c, Threshold__c DESC];

        // Accumulate the fields we need to check for our established notifications.
        // (We need to re-query to populate formula fields)
        
        Set<String> limits = new Set<String>();

        queryString = 'SELECT Id';
        for (Limits_Notification__c n : ns) {
            if (!limits.contains(n.Limit__c)) {
                queryString += ', ' + n.Limit__c;
                limits.add(n.Limit__c);
            }
        }
        queryString += ' FROM Limits_History__c WHERE Id = \'' + lh.Id + '\'';

        lh = (Limits_History__c)Database.query(queryString)[0];

        for (Limits_Notification__c n : ns) {
            Object limitValue = lh.get(n.Limit__c);
            Schema.DisplayType dt = Schema.sObjectType.Limits_History__c.fields.getMap().get(n.Limit__c).getDescribe().getType();
            Boolean runNotification = false;

            if (limitValue == null) {
                limitValue = 0;
            }

            if (dt == Schema.DisplayType.Double || dt == Schema.DisplayType.Percent || dt == Schema.DisplayType.Integer) {
                runNotification = (Double)limitValue > n.Threshold__c;
            } else {
                runNotification = false;
            }

            if (runNotification) {
                // Determine whether we are sending to just one user or to a whole profile (e.g., system administrator)
                List<User> usersToNotify = new List<User>();

                if (n.Send_To_Profile__c) {
                    if (!profileMap.containsKey(n.User__r.ProfileId)) {
                        profileMap.put(n.User__r.ProfileId, [SELECT Email FROM User WHERE ProfileId = :n.User__r.ProfileId]);
                    }

                    usersToNotify.addAll(profileMap.get(n.User__r.ProfileId));
                } else {
                    usersToNotify.add(n.User__r);
                }

                if (n.Method__c == 'Email') {
                    Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();

                    em.setPlainTextBody('Limits Monitor has detected that the limit ' 
                        + Schema.sObjectType.Limits_History__c.fields.getMap().get(n.Limit__c).getDescribe().getLabel() 
                        + ' has exceeded your defined threshold of ' + n.Threshold__c
                        + '. The current value is ' + String.valueOf(limitValue) + '.');
                    em.setSubject('Salesforce Limit Notification');

                    List<String> emails = new List<String>();

                    for (User u : usersToNotify) {
                        emails.add(u.Email);
                    }

                    em.setToAddresses(emails);
                    em.setSaveAsActivity(false);

                    ems.add(em);
                } else {
                    for (User u : usersToNotify) {
                        FeedItem item = new FeedItem();

                        item.Title = 'Limits Notification';
                        item.Body = 'Limits Monitor has detected that the limit ' 
                            + Schema.sObjectType.Limits_History__c.fields.getMap().get(n.Limit__c).getDescribe().getLabel() 
                            + ' has exceeded your defined threshold of ' + n.Threshold__c
                            + '. The current value is ' + String.valueOf(limitValue) + '.';
                        item.ParentId = u.Id;

                        fis.add(item);
                    }
                }
            }
        }

        if (fis.size() > 0) {
            insert fis;
        }

        if (ems.size() > 0 && !Test.isRunningTest()) {
            Messaging.sendEmail(ems);
        }
    }

    public static void rotateLogs() {
        Date hourlyThreshold;
        Date dailyThreshold;
        List<Limits_History__c> lhs;

        hourlyThreshold = Date.today().addDays((Integer)-LimitsHistoryUtilities.hourlyLogsRetentionDays);
        dailyThreshold = Date.today().addDays((Integer)-LimitsHistoryUtilities.dailyLogsRetentionDays);

        lhs = [SELECT Id 
               FROM Limits_History__c 
               WHERE (CreatedDate < :dailyThreshold AND Snapshot_Type__c = :Label.Limits_History_Daily_Snapshot_Type)
                     OR (CreatedDate < :hourlyThreshold AND Snapshot_Type__c = :Label.Limits_History_Hourly_Snapshot_Type)];

         delete lhs;
    }

    @TestVisible
    private static Object getValueByKeyPath(Object q, List<String> keyPath) {
        Object intermediate = q;
        
        for (String key : keyPath) {
            intermediate = ((Map<String, Object>)intermediate).get(key);

            if (intermediate == null) break;
        }

        return intermediate;
    }

}
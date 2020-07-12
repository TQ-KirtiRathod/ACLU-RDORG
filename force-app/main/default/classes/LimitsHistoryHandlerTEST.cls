/*
 *
 *Name  :  ConfDataTriggerHandlerTest
 *Author:  Appirio India 
 *Date  :  May 05,2017
 *Purpose : To Test ConfDataTriggerHandler Class functionality on various trigger events
 *
 */
@isTest
private class LimitsHistoryHandlerTEST {
    
    //Method to test Daily running Tasks
    @isTest
    static void testRunTasksDaily() {
        LimitsHistoryUtilities.configuration.Rotate_Logs__c = true;
        LimitsHistoryUtilities.configuration.Take_Daily_Snapshots__c = true;
        LimitsHistoryUtilities.configuration.Take_Hourly_Snapshots__c = true;
        LimitsHistoryUtilities.configuration.Retention_Daily_Snapshots__c = 1;
        LimitsHistoryUtilities.configuration.Retention_Hourly_Snapshots__c = 1;

        Map < String, Map < String, Integer >> body = new Map < String, Map < String, Integer >> {
            LimitsHistoryUtilities.limitsDataKeys[0] => new Map < String,
            Integer > {
                'Max' => 10,
                'Remaining' => 1
            }
        };

            
        //Calling Mock to receive a fake response 
        Test.setMock(HttpCalloutMock.class,
            new LimitsHistoryCalloutMock(200, 'OK', JSON.serialize(body), new Map < String, String > ()));
        Test.startTest();

        LimitsHistoryHandler.runTasks('');

        Test.stopTest();
        
        //Verify the number of Limit History Records running Daily
        System.assertEquals(1, [SELECT count() FROM Limits_History__c WHERE Snapshot_Type__c =: Label.Limits_History_Daily_Snapshot_Type]);
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME
        ]);
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
        ]);
    }

    //Method to test Hourly Running Tasks
    @isTest
    static void testRunTasksHourly() {
        LimitsHistoryUtilities.configuration.Rotate_Logs__c = true;
        LimitsHistoryUtilities.configuration.Take_Daily_Snapshots__c = true;
        LimitsHistoryUtilities.configuration.Take_Hourly_Snapshots__c = true;
        LimitsHistoryUtilities.configuration.Retention_Daily_Snapshots__c = 1;
        LimitsHistoryUtilities.configuration.Retention_Hourly_Snapshots__c = 1;
        Map < String, Map < String, Integer >> body = new Map < String, Map < String, Integer >> {
            LimitsHistoryUtilities.limitsDataKeys[0] => new Map < String,
            Integer > {
                'Max' => 10,
                'Remaining' => 1
            }
        };

        Test.setMock(HttpCalloutMock.class,
            new LimitsHistoryCalloutMock(200, 'OK', JSON.serialize(body), new Map < String, String > ()));

        Test.startTest();
        //Run the Hourly Snapshots
        LimitsHistoryHandler.runTasks(LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME);

        Test.stopTest();
        //Number of Limits History records where Snapshot is running Hourly
        System.assertEquals(1, [SELECT count() FROM Limits_History__c WHERE Snapshot_Type__c =: Label.Limits_History_Hourly_Snapshot_Type]);
    }

    //Method to test the cancellation of Hourly job
    @isTest
    static void testSelfHealHourlyJob() {
        /*System.assertEquals(0, [SELECT count() 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME]);*/

        LimitsHistoryUtilities.configuration.Take_Hourly_Snapshots__c = true;

        LimitsHistoryHandler.selfHealHourlyJob();
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
        ]);

        LimitsHistoryHandler.selfHealHourlyJob();
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
        ]);

        String oldValue = LimitsHistoryUtilities.hourlyCronString;

        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
            AND CronExpression =: oldValue
        ]);

        //Cron expression changed
        LimitsHistoryUtilities.configuration.Hourly_Cron_String__c = '0 57 * * * ?';
        LimitsHistoryHandler.selfHealHourlyJob();

        //Cancel the hourly jobs scheduled earlier
        System.assertEquals(0, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
            AND CronExpression =: oldValue
        ]);
        
        //Jobs to run at new Cron
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
            AND CronExpression = '0 57 * * * ?'
        ]);

        LimitsHistoryUtilities.configuration.Take_Hourly_Snapshots__c = false;
        
        //user has deactivated hourly snapshots. 
        LimitsHistoryHandler.selfHealHourlyJob();
        System.assertEquals(0, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_HOURLY_JOB_NAME
        ]);
    }

    //Method for cancellation of Daily jobs
    @isTest
    static void testSelfHealDailyJob() {
        /*System.assertEquals(0, [SELECT count() 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME]);*/

        LimitsHistoryHandler.selfHealDailyJob();
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME
        ]);

        LimitsHistoryHandler.selfHealDailyJob();
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME
        ]);

        String oldValue = LimitsHistoryUtilities.dailyCronString;

        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME
            AND CronExpression =: oldValue
        ]);

        //New Cron expression for the jobs
        LimitsHistoryUtilities.configuration.Daily_Cron_String__c = '0 0 22 * * ?';
        LimitsHistoryHandler.selfHealDailyJob();

        
        //Number of jobs left for previous Cron
        System.assertEquals(0, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME
            AND CronExpression =: oldValue
        ]);
        
        //Number of jobs for new Cron
        System.assertEquals(1, [SELECT count()
            FROM CronTrigger
            WHERE CronJobDetail.Name =: LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME
            AND CronExpression = '0 0 22 * * ?'
        ]);
    }

    
    //Method to test request for limit information
    @isTest
    static void testWriteLimitsHistory() {
        Map < String, Map < String, Integer >> body = new Map < String, Map < String, Integer >> {
            LimitsHistoryUtilities.limitsDataKeys[0] => new Map < String,
            Integer > {
                'Max' => 10,
                'Remaining' => 1
            }
        };

        Test.setMock(HttpCalloutMock.class,
            new LimitsHistoryCalloutMock(200, 'OK', JSON.serialize(body), new Map < String, String > ()));
        Test.startTest();

        LimitsHistoryHandler.writeLimitsHistory(Label.Limits_History_Daily_Snapshot_Type);

        Test.stopTest();

        String dataKeys = LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_M__c, ' + LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_R__c';

        Limits_History__c lh = Database.query('SELECT ' + dataKeys + ' FROM Limits_History__c');

        //Verify the updates
        System.assertEquals(10, lh.get(LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_M__c'));
        System.assertEquals(1, lh.get(LimitsHistoryUtilities.limitsDataKeys[0].left(34) + '_R__c'));
    }

    
    //Method to generate history
    @isTest
    static void testGenerateLimitsHistory() {
        Map < String, Object > m = new Map < String, Object > ();
        List < String > dataKeys = new List < String > {
            LimitsHistoryUtilities.limitsDataKeys[0],
            LimitsHistoryUtilities.limitsDataKeys[1]
        };
        Limits_History__c lh;

        for (String k: dataKeys) {
            m.put(k, new Map < String, Object > {
                'Max' => 12,
                'Remaining' => 3
            });
        }

        lh = LimitsHistoryHandler.generateLimitsHistory(m, dataKeys, Label.Limits_History_Daily_Snapshot_Type);

        //Verify the populated fields
        System.assertEquals(12, lh.get(dataKeys[0].left(34) + '_M__c'));
        System.assertEquals(12, lh.get(dataKeys[1].left(34) + '_M__c'));
        System.assertEquals(3, lh.get(dataKeys[0].left(34) + '_R__c'));
        System.assertEquals(3, lh.get(dataKeys[1].left(34) + '_R__c'));

        for (Limits_History_Item__mdt i1: [SELECT Destination_Field__c
                FROM Limits_History_Item__mdt
                ORDER BY DeveloperName ASC
                LIMIT 99
            ]) {
            //Destination field populated
            System.assertNotEquals(null, lh.get(i1.Destination_Field__c));
        }

        //Verify the updated value
        System.assertEquals(Label.Limits_History_Daily_Snapshot_Type, lh.Snapshot_Type__c);

    }

    //Method to send Notification to Users
    @isTest
    static void testSendUserNotifications() {
        Map < String, Object > m = new Map < String, Object > ();
        List < String > dataKeys = new List < String > {
            LimitsHistoryUtilities.limitsDataKeys[0],
            LimitsHistoryUtilities.limitsDataKeys[1]
        };
        Limits_History__c lh;
        User u = [SELECT Id, ProfileId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

        for (String k: dataKeys) {
            m.put(k, new Map < String, Object > {
                'Max' => 12,
                'Remaining' => 3
            });
        }

        lh = LimitsHistoryHandler.generateLimitsHistory(m, dataKeys, Label.Limits_History_Daily_Snapshot_Type);
        insert lh;

        List < Limits_Notification__c > lns = new List < Limits_Notification__c > {
            new Limits_Notification__c(User__c = u.Id,
                Limit__c = dataKeys[0].left(34) + '_U__c',
                Threshold__c = 0,
                Method__c = 'Chatter',
                Send_to_Profile__c = true),
            new Limits_Notification__c(User__c = u.Id,
                Limit__c = dataKeys[0].left(34) + '_M__c',
                Threshold__c = 0,
                Method__c = 'Email')
        };

        insert lns;

        LimitsHistoryHandler.sendUserNotifications(lh);

        List < FeedItem > fis = [SELECT Title, Body FROM FeedItem];

        //Verify the Notification received at user's feed
        System.assertEquals([SELECT count() FROM User WHERE ProfileId =: u.ProfileId], fis.size());
        System.assertEquals('Limits Notification', fis[0].Title);
        System.assert(fis[0].Body.contains(Schema.sObjectType.Limits_History__c.fields.getMap().get(dataKeys[0].left(34) + '_U__c').getDescribe().getLabel()));
    }

    //Method to delete jobs whose created dates are newer than Thresholds
    @isTest
    static void testRotateLogs() {
        LimitsHistoryUtilities.configuration.Rotate_Logs__c = true;
        LimitsHistoryUtilities.configuration.Retention_Daily_Snapshots__c = 1;
        LimitsHistoryUtilities.configuration.Retention_Hourly_Snapshots__c = 1;

        List < Limits_History__c > lhs = new List < Limits_History__c > {
            new Limits_History__c(Snapshot_Type__c = Label.Limits_History_Hourly_Snapshot_Type),
            new Limits_History__c(Snapshot_Type__c = Label.Limits_History_Daily_Snapshot_Type),
            new Limits_History__c(Snapshot_Type__c = Label.Limits_History_Daily_Snapshot_Type),
            new Limits_History__c(Snapshot_Type__c = Label.Limits_History_Hourly_Snapshot_Type)
        };

        insert lhs;

        // Configure the CreatedDates - two records today, one day before yesterday (1 full day retention),
        // one a year ago.

        Test.setCreatedDate(lhs[0].Id, DateTime.now());
        Test.setCreatedDate(lhs[1].Id, DateTime.now());
        Test.setCreatedDate(lhs[2].Id, DateTime.now().addDays(-2));
        Test.setCreatedDate(lhs[3].Id, DateTime.now().addDays(-365));

        LimitsHistoryHandler.rotateLogs();

        //Verify the jobs left
        System.assertEquals(2, [SELECT count() FROM Limits_History__c WHERE CreatedDate = TODAY]);
    }

    //Method to get Values using the keys
    @isTest
    static void testGetValueByKeyPath() {
        Map < String, Object > test = new Map < String, Object > {
            'test' => (Object) 2,
            'test2' => (Object)(new Map < String, Object > {
                'test3' => (Object) 4
            })
        };

        //Verify the value for test
        System.assertEquals(2, (Integer) LimitsHistoryHandler.getValueByKeyPath(test, new List < String > {
            'test'
        }));
        //Verify the value for Test2 containing Test3
        System.assertEquals(4, (Integer) LimitsHistoryHandler.getValueByKeyPath(test, new List < String > {
            'test2',
            'test3'
        }));
        System.assertEquals(null, LimitsHistoryHandler.getValueByKeyPath(test, new List < String > {
            'test4'
        }));
    }
}
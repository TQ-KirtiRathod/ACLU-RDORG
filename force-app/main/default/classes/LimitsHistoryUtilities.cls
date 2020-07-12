/*
*
*Name  :  LimitsHistoryUtilities
*Author:  ACLU (David Reed)
*Date  :  July 07, 2017
*Purpose : Class contains getter methods to support the Limits classes
*
*/
public with sharing class LimitsHistoryUtilities {
    public static final String LIMITS_DAILY_JOB_NAME = 'LIMITS_DAILY_JOB';
    public static final String LIMITS_HOURLY_JOB_NAME = 'LIMITS_HOURLY_JOB';

    public static final List<String> limitsDataKeys = new List<String>{   
        // This list can be extended as Salesforce adds new elements to the Limits API
        // Just ensure that the appropriate fields are set up on the Limits_History__c object to receive them.
        'ConcurrentAsyncGetReportInstances',
        'ConcurrentSyncReportRuns',
        'DailyApiRequests',
        'DailyAsyncApexExecutions',
        'DailyBulkApiRequests',
        'DailyDurableGenericStreamingApiEvents',
        'DailyDurableStreamingApiEvents',
        'DailyGenericStreamingApiEvents',
        'DailyStreamingApiEvents',
        'DailyWorkflowEmails',
        'DataStorageMB',
        'DurableStreamingApiConcurrentClients',
        'FileStorageMB',
        'HourlyAsyncReportRuns',
        'HourlyDashboardRefreshes',
        'HourlyDashboardResults',
        'HourlyDashboardStatuses',
        'HourlyODataCallout',
        'HourlySyncReportRuns',
        'HourlyTimeBasedWorkflow',
        'MassEmail',
        'SingleEmail',
        'StreamingApiConcurrentClients'
    };

    public static LimitsMonitorConfiguration__c configuration {
        public get {
            if (configuration == null) {
                configuration = LimitsMonitorConfiguration__c.getOrgDefaults();
            } 

            return configuration;
        }
    }

    public static Boolean shouldRotateLogs { 
        get { 
            return (configuration.Rotate_Logs__c != null ? configuration.Rotate_Logs__c : true); 
        } 
    }
    public static Boolean shouldRunDailySnapshots { 
        get { 
            return (configuration.Take_Daily_Snapshots__c != null ? configuration.Take_Daily_Snapshots__c : true); 
        }
    } 

    public static Boolean shouldRunHourlySnapshots { 
        get { 
            return (configuration.Take_Hourly_Snapshots__c != null ? configuration.Take_Hourly_Snapshots__c : true); 
        }
    } 

    public static Integer dailyLogsRetentionDays {
        get {
            return (configuration.Retention_Daily_Snapshots__c != null ?
                Integer.valueOf(configuration.Retention_Daily_Snapshots__c)
                : 7);
        }
    }

    public static Integer hourlyLogsRetentionDays {
        get {
            return (configuration.Retention_Hourly_Snapshots__c != null ? 
                Integer.valueOf(configuration.Retention_Hourly_Snapshots__c)
                : 3);
        }
    }

    public static String hourlyCronString {
        get {
            return (String.isNotBlank(configuration.Hourly_Cron_String__c) ? configuration.Hourly_Cron_String__c : '0 0 * * * ?');
        }
    }

    public static String dailyCronString {
        get {
            return (String.isNotBlank(configuration.Daily_Cron_String__c) ? configuration.Daily_Cron_String__c : '0 0 23 * * ?');
        }
    }

}
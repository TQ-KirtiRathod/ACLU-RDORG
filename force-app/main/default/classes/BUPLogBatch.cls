/*This class is a batch class used to create BUP_Log records to track failed Apex Jobs
Added By : RoundCorner Team ZenDesk #65149*/
public class BUPLogBatch implements Database.Batchable<sObject>{
    public  String queryString;
    public set<String> statusSet = new set<String>{'Failed'};
    public set<String> jobType = new set<String>{'ScheduledApex','BatchApex'};
    public rC_BUP__Batch_Upload_Framework_Settings__c bupFrameworkSetting = rC_BUP__Batch_Upload_Framework_Settings__c.getOrgDefaults();
    public DateTime lastLogDateTime = bupFrameworkSetting.LastLogTime__c;
    public DateTime timeNow = DateTime.newInstance(System.now().year(), System.now().month(), System.now().day(), System.now().hour(), System.now().minute(), 0);
    public DateTime lastLogTime; 
    
   // Constructor of batch class
    public BUPLogBatch() {
        if(lastLogDateTime != null) {
        lastLogTime = DateTime.newInstance(lastLogDateTime.year(), lastLogDateTime.month(), lastLogDateTime.day(), lastLogDateTime.hour(),lastLogDateTime.minute(), 0);
        }else {
            lastLogTime = DateTime.newInstance(2018,12, 31, 23,59, 59); 
        }
        queryString = 'SELECT Id, ApexClassID, ApexClass.Name, CompletedDate';
        queryString  += ', ExtendedStatus, JobItemsProcessed, JobType, MethodName';
        queryString  += ', Status, TotalJobItems,CreatedById';
        queryString  += ' FROM AsyncApexJob WHERE (Status =: statusSet OR ExtendedStatus != null)';
        queryString  += ' AND JobType = :jobType';
        queryString  += ' AND (ApexClass.Name Like \'BUP%\' OR ApexClass.Name like \'BUF%\')';
        queryString  += ' AND CreatedDate < :timeNow AND CreatedDate >= :lastLogTime';
        System.debug('queryString ***' + queryString);
        if(test.isRunningTest()) {
            queryString = '';
            queryString = 'SELECT Id, ApexClassID, ApexClass.Name, CompletedDate';
            queryString  += ', ExtendedStatus, JobItemsProcessed, JobType, MethodName';
            queryString  += ', Status, TotalJobItems,CreatedById';
            queryString  += ' FROM AsyncApexJob';
            
        }
    }
        
    Public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    Public void execute(Database.BatchableContext BC, List<AsyncApexJob> scope){
        List<BUP_Log__c> bupLogs = new List<BUP_Log__c>();
        //Create BUP Log records and insert it
        for(AsyncApexJob jobs :scope) {
            BUP_Log__c log = new BUP_Log__c();
            log.Details__c = 'Job Name: '+ jobs.ApexClass.Name +'; Id:'+jobs.Id;
            log.Error_Message__c = jobs.ExtendedStatus;
            log.Completed_Time__c = jobs.CompletedDate;
            log.Type__c = jobs.JobType;
            log.Status__c = jobs.Status;
            log.Created_By__c = jobs.CreatedById;
            bupLogs.add(log);  
        }
        List<Database.saveresult> saveResult = Database.insert(bupLogs,false);
        for (Database.SaveResult sr : saveResult) {
            if (!sr.isSuccess()) {          
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
    
    Public void finish(Database.BatchableContext BC) {
        //Reschedule the Scheduler 
        bupFrameworkSetting.LastLogTime__c =  timeNow;
        update bupFrameworkSetting;
        List<AsyncApexJob> asyncApexJobList =  getAsyncJob();
        if (asyncApexJobList == null || asyncApexJobList.size() == 0) {
            BUPLogScheduler  scheduler = new BUPLogScheduler();
            if(bupFrameworkSetting.BUPLogTimeoutInMinutes__c != null) {
                Datetime  sysTime = System.now().addMinutes(bupFrameworkSetting.BUPLogTimeoutInMinutes__c.intValue()); //Adding additional 20 sec to reschedule again in case of exceptions
                String jobName = BUPLogScheduler.Class.getName() + sysTime;
                String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
                System.schedule(jobName, chronExpression, scheduler); 
            }
        
        }
        
    }
    
    private List<AsyncApexJob> getAsyncJob() {
        return [
            SELECT Id
                 , ApexClass.Name
                 , Status
                 , JobType 
              FROM AsyncApexJob  
             WHERE JobType IN ('BatchApexWorker','ScheduledApex') 
               AND Status IN ('Preparing','Queued','Processing','Holding') 
               AND ApexClass.Name = 'BUPLogScheduler'
        ];
    }
}
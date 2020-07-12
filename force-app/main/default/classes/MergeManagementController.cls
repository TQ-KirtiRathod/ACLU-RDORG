/*
*
*Name  :  MergeManagementController
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  April 21, 2017
*Purpose : Controller class for MergeManagement page. Pages is linked to Drawloop MassAcknowledgements page.  
*          Logic will reset acknowledged opportunities 
*
*/
public class MergeManagementController {
    public String mergeJobNumber{get;set;}
    public String mergeJobNumberOpp{get;set;}
    public MergeManagementController() {
        
    }
    public PageReference submit() {
        if(!String.isBlank(mergeJobNumber)) {
            list<Task> taskList = [SELECT Id, Status, Fulfilled_Date__c, Merge_Job_Number__c 
                                        FROM Task WHERE Merge_Job_Number__c = :mergeJobNumber];
            
            if(taskList.size() == 0) {
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'No matching task records found.');
                ApexPages.addMessage(errorMsg);
                return null;
            }
            for(Task t : taskList) {
                t.Status = 'In progress';
                t.Fulfilled_Date__c = null;
                t.Merge_Job_Number__c = '';
            }
            try{
                update taskList;
                ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, taskList.size() + ' task records updated.');
                ApexPages.addMessage(successMsg);
                return null;
            }catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('MergeManagementController','submit',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
            return null;
        } else {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter Merge Job Number for task');
            ApexPages.addMessage(errorMsg);
            return null;
        }
    }
    
    public PageReference submitOpp() {
        if(!String.isBlank(mergeJobNumberOpp)) {
            list<Opportunity> oppList = [SELECT Id, rC_Giving__Acknowledged_Date__c, Recipient_Acknowledgement_Status__c, Acknowledgment_Status__c, Merge_Job_Number__c 
                                        FROM Opportunity WHERE Merge_Job_Number__c = :mergeJobNumberOpp];
            
            if(oppList.size() == 0) {
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'No matching Opportunity records found.');
                ApexPages.addMessage(errorMsg);
                return null;
            }
            for(Opportunity opp : oppList) {
                opp.Merge_Job_Number__c = '';
                opp.rC_Giving__Acknowledged_Date__c = null;
                opp.Acknowledgment_Status__c = 'N - Not Acknowledged';
                opp.Recipient_Acknowledgement_Status__c = 'N - Not Acknowledged';
            }
            try{
                update oppList;
                ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, oppList.size() + ' opportunity records updated.');
                ApexPages.addMessage(successMsg);
                return null;
            }catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('MergeManagementController','submitOpp',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
            return null;
        } else {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter Merge Job Number for Opportunity');
            ApexPages.addMessage(errorMsg);
            return null;
        }
    }
}
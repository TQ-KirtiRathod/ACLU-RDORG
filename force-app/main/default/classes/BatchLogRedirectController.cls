/*
*
*Name  :  BatchLogRedirectController
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  Feb 20, 2017
*Purpose : Controller class for BatchLogRedirectPage and BatchLogEditRedirectPage
*          Logic passes the currect URL key value pairs
*
*/
public class BatchLogRedirectController {
    public BatchLogRedirectController(ApexPages.StandardController controller) {
    }        
    
    public static PageReference redirect() {
        PageReference p;
        Id batchId = ApexPages.currentPage().getParameters().get('id');
        String objPrefix = Batch_Log__c.sobjecttype.getDescribe().getKeyPrefix();
        Batch_Log__c batchLogRec = [SELECT RecordTypeId, RecordType.Name FROM Batch_Log__c WHERE Id = :batchId];
        if(batchLogRec.RecordType.Name == 'Manual') {
            p = new PageReference('/apex/BatchLogDetailPage?ent=' + System.Label.BatchLogObjectId + '&id=' + batchId 
              + '&RecordType=' + batchLogRec.RecordTypeId + '&retURL=%2F'+objPrefix+'%2Fo');
        } else {
            p = new PageReference('/' + batchId);
            p.getParameters().put('nooverride', '1');
        }
        return p;
    }
    
    public static PageReference editRedirect() {
        PageReference p;
        Id batchId = ApexPages.currentPage().getParameters().get('id');
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        String objPrefix = Batch_Log__c.sobjecttype.getDescribe().getKeyPrefix();
        Batch_Log__c batchLogRec = [SELECT RecordTypeId, RecordType.Name FROM Batch_Log__c WHERE Id = :batchId];
        if(batchLogRec.RecordType.Name == 'Manual') {
            p = new PageReference('/apex/BatchLogDetailPage?ent=' + System.Label.BatchLogObjectId + '&id=' + batchId 
              + '&RecordType=' + batchLogRec.RecordTypeId + '&e=1');
        } else {
            p = new PageReference('/' + batchId + '/e');
            p.getParameters().put('nooverride', '1');
        }
        p.getParameters().put('retURL', retURL);
        return p;
    }
}
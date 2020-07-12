/*
*
*Name  :  BatchResetMembership
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  April 02, 2018
*Purpose : This Batch Class will be executed on click of 'Reset Membership/Sharing & Release' button on BatchLogDetailPage
*
*/
global class BatchResetMembership implements Database.Batchable<sObject>, Database.Stateful{
    global Id batchLogId;
    global Set<Id> accIds;
    global String email;
    global String batchname;
    
    global BatchResetMembership(Id bLogId) {
        accIds = new Set<Id>();
        this.batchLogId = bLogId;
        String userId = UserInfo.getUserId();
        User activeUser = [Select Email From User where Id = : userId limit 1];
        this.email = activeUser.Email;
    }
    
    global Database.QueryLocator start(Database.BatchableContext Bc){
        //Get Child Oppportunitites from BatchLog
        return Database.getQueryLocator([SELECT Id ,AccountId , Sharing_Code__c, rC_Giving__External_ID__c,New_Membership_Set_To_Date__c, Batch_Log__r.Name,
                                            Account.Original_Join_Date__c, Account.Last_Membership_Gift__c, Account.Last_Membership_Gift__r.CloseDate
                                            FROM Opportunity WHERE Batch_Log__c =: batchLogId
                                            AND rC_Giving__External_ID__c = 'Flagged for MembershipShareCode Reset']);
    }
    
    global void execute(Database.BatchableContext Bc, List<Opportunity> opportunitiesToUpdate){
        if( accIds.contains(opportunitiesToUpdate[0].AccountId) ){
            accIds.add(new BatchLogManager().BatchResetMembershipMethod(opportunitiesToUpdate[0], false));
        } else {
            accIds.add(new BatchLogManager().BatchResetMembershipMethod(opportunitiesToUpdate[0], true));
        }
        
    
    
    }
    
    
    global void finish(Database.BatchableContext Bc){
        //Update BatchLog to Balanced
        Batch_Log__c batchLog = [Select Id, Name, Actual_Count__c FROM Batch_Log__c WHERE id =: batchLogId LIMIT 1];
        String batchname = batchLog.Name;
        Boolean asyncReq = BatchLogDetailPageController.IsAsyncProcessingRequired(batchLog.Actual_Count__c);
        if( asyncReq ){
            batchLog.Error_Details__c = 'Processing';
        } else {
            batchLog.Error_Details__c = null;
        }
        batchLog.Has_Error_Details__c = false;
        
        batchLog.Batch_Log_Status__c = 'Balanced';
        
        
        update batchLog;
        if( asyncReq ){
            DataBase.executeBatch(new ReleaseBatchLog_Batch(batchLog.Id, userInfo.getUserEmail()), 40);
        }
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm() + '/'; 
        String htmlBody = 'Membership and Revenue Sharing has been reassessed and evaluated for the following:</br></br>';
        //open table..
        htmlBody += '<table border="0" ><caption style="text-align:left">BatchLog:<a href='+sfdcURL+batchLogId+'> '+batchname+'</a></caption><br></br><tr><th style="text-align:left">Account Name</th></tr>';
        for(Account acc: [Select Id, Name From account where id in: accIds]){
            htmlBody += '<tr><td><a href='+sfdcURL+acc.Id+'>' + acc.Name + '</a></td></tr>';
        }
        htmlBody += '</table>';
        
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        String[] sendingTo = new String[]{email}; 
        semail.setToAddresses(sendingTo); 
        
        semail.setSubject('Membership and Revenue Sharing has been reassessed : '+batchname); 
        semail.setHtmlBody(htmlBody); 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail}); 
        
    }

}
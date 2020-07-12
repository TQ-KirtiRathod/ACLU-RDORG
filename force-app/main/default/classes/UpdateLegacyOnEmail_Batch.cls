/*
*Name  :  UpdateLegacyOnEmail_Batch
*Author:  roundCorner Inc. (Kirti Rathod)
*Date  :  April 02, 2019
*Purpose : It's one time script to update PIDI email IDs to a new legacy email ID field and 
*          regenerate all the External IDs with the format that is being used now. 
*          This will help prevent duplicates being constantly introduced into Salesforce 
*          and will also streamline these and other updates to the email records
*/
//Created a Batchclass by RoundCorner ZenDesk #57433
public without sharing Class UpdateLegacyOnEmail_Batch implements Database.Batchable<sObject>, Database.Stateful {
// Get all email records with combination of ContactId+Email
   public String queryString;
   String failureIds = '';
   public String[] emailIdList;
   public DateTime startDateTime;
   public DateTime endDateTime;
   
   public UpdateLegacyOnEmail_Batch() { }
   public UpdateLegacyOnEmail_Batch(String emailIdStr) {
      if(String.isBlank(emailIdStr)) {
		return;
	  }
	  emailIdList = new String[]{ };
	  emailIdList.addAll(emailIdStr.split(','));
   }
   
   public UpdateLegacyOnEmail_Batch(DateTime startDateTime, DateTime endDateTime) {
		if(startDateTime == null || endDateTime == null) {
			return;
		}
		//Format:: 2018-03-01T00:00:00Z
		this.startDateTime = startDateTime;
		this.endDateTime = endDateTime;
   }
   
   public UpdateLegacyOnEmail_Batch(DateTime startDateTime) {
		if(startDateTime == null) {
			return;
		}
		//Format:: 2018-03-01T00:00:00Z
		this.startDateTime = startDateTime;
   }
   
	public Database.QueryLocator start(Database.BatchableContext BC){
   		queryString = 'SELECT Id, Email_address__c,  Contact__c, External_Id__c';
        queryString += ' FROM Email__c ';
        
		if(emailIdList != null && emailIdList.size() > 0) {
		    queryString += ' WHERE Email_address__c IN :emailIdList';
		} else if(startDateTime != null && endDateTime != null) {
			queryString += ' WHERE CreatedDate >= :startDateTime AND CreatedDate <= :endDateTime';
		} else if(startDateTime != null){
			queryString += ' WHERE CreatedDate >= :startDateTime';
		}
        System.debug('query :: ' + queryString);
        return Database.getQueryLocator(queryString);
	}
	
	public void execute(Database.BatchableContext BC, List<Email__c> emailList){
   System.debug('emailList>>>>>>>>>>' + emailList);
        //Update email records
        List<Email__c> emailUpdateList = new List<Email__c>();
        for(Email__c emailObj :emailList) {
			
            if(emailObj.External_Id__c != null && !emailObj.External_Id__c.startsWith('003')) {
                emailObj.External_Id__c = emailObj.Contact__c + '_' + emailObj.Email_address__c;
                emailUpdateList.add(emailObj);
            }
        }
        //Get the failure records
        if(emailUpdateList.size() > 0) {
        List<Database.SaveResult> saveResult = database.update(emailUpdateList,false);
        
        for (Integer i = 0; i < emailUpdateList.size(); i++) {
            if (!saveResult[i].isSuccess()) {
                for(Database.Error err : saveResult[i].getErrors()) {
                    failureIds += emailUpdateList[i].Id +' '+ err.getMessage()+'  ';
                    System.debug(err.getMessage());
                }
            }
        }
        System.debug(failureIds);
        }      
    }    
	public void finish(Database.BatchableContext BC) {
    	//Send an email 
        if(!String.isBlank(failureIds)) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { 'nshrikhande@salesforce.com'};
            message.subject = '#57433 - Email Update Failed Result';
            message.plainTextBody = ' All failed Email result: '+failureIds;  
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    
    }
}
/*
*
*Name  :  EmailTriggerHandler
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 14, 2016
*Purpose :  Handler class for EmailTrigger. 
            Includes trigger operations for insert/update/delete case. 
            Contains methods to check for duplicate emails on contacts and to set Primary checkbox on Email.
*           Bypassed during DC Merges - 2019-08-21, DS
*/
public class EmailTriggerHandler {

    public static list<Id> listContact;
    
    //ZD-57283
    public static Set<String> UNDELIVERABLE_STATUSES = 
      new Set<String>{'Hard Bounce','Soft Bounce','Invalid','Other Undeliverable Reason'};

    public static list<AsyncRequest__c> newAsyncRequest = new list<AsyncRequest__c>();
    public static double emailAsyncBatchMax;
    public static Boolean asyncFunctionCalled = false;
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
           // emailAsyncBatchMax = 1;
            emailAsyncBatchMax = q.Batch_Size_Email__c;
        } else {
            emailAsyncBatchMax = 100;
        }
    }

    public static void mainEntry(List<Email__c> newList, List<Email__c> oldList, Map<Id,Email__c> newMap, Map<Id,Email__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {

        //if trigger is active
        if(TriggerState.isActive('Email_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {


            // It is called on before insert
            if(isBefore) {
                if(isInsert) {
                    if (ACLUMergeManager.triggersDisabledMap.get('Email') == NULL || ACLUMergeManager.triggersDisabledMap.get('Email') == FALSE) {
                        BeforeInsert(newList);
                    }
                }
            }


            // It is called on before update
            if(isBefore) {
                if(isUpdate) {
                    if (ACLUMergeManager.triggersDisabledMap.get('Email') == NULL || ACLUMergeManager.triggersDisabledMap.get('Email') == FALSE) {
                        BeforeUpdate(newList, oldMap);
                    }
                }
                if(isDelete) {
                    beforeDelete(oldList);
                }   

            }

            if(isAfter) {
                if(isInsert) {
                   AfterInsert(newList);
                }

            }

            if(isAfter) {
                if(isUpdate) {
                    if (ACLUMergeManager.triggersDisabledMap.get('Email') == NULL || ACLUMergeManager.triggersDisabledMap.get('Email') == FALSE) {
                        AfterUpdate(newList,oldMap);
                    }
                }             
            }

        }

    }

    /*
*
*Method BeforeUpdate
*calls onBeforeUpdate
*
*/
    public static void BeforeUpdate(List<Email__c> newEmails, Map<Id,Email__c> oldMap){
        // check for duplicate Emails existing for Contact
        List<Email__c> listOfEmailsToProcess = new List<Email__c>();
        for(Email__c theEmail : newEmails) {
          if((theEmail.Contact__c != oldMap.get(theEmail.Id).Contact__c) || (theEmail.Email_Address__c != oldMap.get(theEmail.Id).Email_Address__c) || 
              (theEmail.External_Id__c != oldMap.get(theEmail.Id).External_Id__c)) {
            listOfEmailsToProcess.add(theEmail);    
          }    
        }
        if(!listOfEmailsToProcess.isEmpty())
          addErrorIfEmailExistsForContact(listOfEmailsToProcess);
        
        for(Email__c em: newEmails){
            
          // preventDuplicateEmailRecord . Updates the External Id
          if(String.isBlank(em.External_Id__c)) {
            em.External_Id__c = String.valueOf(em.Contact__c).Substring(0,15)+'_'+em.Email_Address__c;
          }

          if (em.Opt_In__c != oldMap.get(em.Id).Opt_In__c) {
            if (!EmailOptOutProcessor.isEmailInScope(em.Id)) {
                // Ignore changes that are being made by the opt-out processor.
                em.Opt_In_Status_Changed__c = true;
            }
            // ZD-57283 START           
            if (em.Opt_In__c == FALSE && em.Opt_Out_Date__c == NULL) {
                em.Opt_Out_Date__c = Date.Today();
            }
            // ZD-57283 END
          }
          // ZD-57283 START
          Email__c oldEm = oldMap.get(em.Id);
          handleUndeliverable(em, oldEm);
          // ZD-57283 END

        }
        
    }

/*
*
*Method BeforeInsert
*calls BeforeInsert
*
*/
    public static void BeforeInsert(List<Email__c> newEmails){
        // check for duplicate Emails existing for Contact
        addErrorIfEmailExistsForContact(newEmails);

        Map<Id,list<Email__c>> mapContactemails= new Map<Id,list<Email__c>>();
        set<Id> setContactIds = new set<Id>();
        for(Email__c em : newEmails) {
            // Populate External Id if null
            if(String.isBlank(em.External_Id__c)) {
                em.External_Id__c = String.valueOf(em.Contact__c).Substring(0,15)+'_'+em.Email_Address__c;
            }

            // markedFirstEmailPrimary
            //check for email's preferred and if its contact is not null
            if(em.Primary__c != true && em.Contact__c != null){
                mapContactemails.put(em.Contact__c,new list<Email__c>());
                mapContactemails.get(em.Contact__c).add(em);
            }
            //If for the same contact another email's preferred is true
            //the contact is stored in setContactIds.
            else if(em.Primary__c == true && mapContactemails.containsKey(em.Contact__c)){
                setContactIds.add(em.Contact__c);
            }

            em.Opt_In_Status_Changed__c = true;
        }

        // markedFirstEmailPrimary
        markedFirstEmailPrimary(setContactIds, mapContactemails);
    }

    public static void AfterInsert(List<Email__c> newEmails) {
      list<Id> idsForAsync_Email = new list<Id>();
      Map<Id,list<Email__c>> mapContactemails= new Map<Id,list<Email__c>>();
      Map<Id,String> mapOfContactIdVsEmailAddress = new Map<Id,String>();

      for(Email__c em : newEmails) {
        if(em.Primary__c == TRUE && em.Contact__c != null && em.Email_address__c != null){
          idsForAsync_Email.add(em.Id);
          mapOfContactIdVsEmailAddress.put(em.Contact__c, em.Email_address__c);
        }
      }
        
        // Modified by :: roundCorner Inc. :: 18-Jan-2019
      // Zendesk: #57475
      // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
        if(idsForAsync_Email.size() > 0){
          newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='email_primarySet', Object_API_Name__c = 'Email__c',
                                    Params__c = String.join(idsForAsync_Email,',')));
          try {
              System.debug(newAsyncRequest);
              System.debug(idsForAsync_Email);
            insert newAsyncRequest;
          } catch(Exception ex){
              apexLogHandler.apexLog log = new apexLogHandler.apexLog('EmailTriggerHandler','AfterInsert',ex.getMessage());
              log.logException(ex);
              log.saveLogs();
            // or suggest using our ApexLog Asset to record the fail!
          }

          // Zendesk: #59182
          idsForAsync_Email.clear();
        }

        /*if(mapOfContactIdVsEmailAddress!= null) {
          //setPrimaryEmailOnContact(mapOfContactIdVsEmailAddress);
        }*/
    }

    public static void AfterUpdate(List<Email__c> newEmails, Map<Id,Email__c> oldMap) {
      list<Id> idsForAsync_Email = new list<Id>();
      Map<Id,String> mapOfContactIdVsEmailAddress = new Map<Id,String>();
      if( asyncFunctionCalled == False ){
          for(Email__c em : newEmails) {
              if( em.Contact__c != null && em.Email_address__c != null && oldMap.get(em.Id).Primary__c != em.Primary__c ){
                  idsForAsync_Email.add(em.Id);
              }
          }
      }
      
        // Modified by :: roundCorner Inc. :: 18-Jan-2019
      // Zendesk: #57475
       // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
      if(idsForAsync_Email.size() > 0){
        newAsyncRequest.add( new AsyncRequest__c(
                                AsyncType__c ='email_primarySet', Object_API_Name__c = 'Email__c',
                                Params__c = String.join(idsForAsync_Email,',')));
        try {
          insert newAsyncRequest;
          //Zendesk: #59182
          idsForAsync_Email.clear();

        } catch(Exception ex){
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('EmailTriggerHandler','AfterUpdate',ex.getMessage());
            log.logException(ex);
            log.saveLogs();
          // or suggest using our ApexLog Asset to record the fail!
        }
          
      }
    }
    
    
    public static void beforeDelete( List<Email__c> oldList ){
        List<Id> contactIds = new List<Id>();
        Map<Id, String> contactIdWithEmailAddMap = new Map<Id, String>();
        List<Contact> contactToUpdate = new List<Contact>();
        for(Email__c email : oldList){
            if(email.Primary__c == TRUE)
                contactIds.add( email.contact__c );
        }
        for( Email__c email: [Select id, contact__c, Email_address__c 
                                FROM Email__c 
                                    where Contact__c in: contactIds 
                                        AND Primary__c = TRUE
                                        AND Id Not IN: oldList]){
            contactIdWithEmailAddMap.put( email.Contact__c, email.Email_address__c );
        }
        for( Id contId : contactIds ){
            if( contactIdWithEmailAddMap.containsKey(contId)){
                contactToUpdate.add(new Contact(Id = contId, rC_Bios__Home_Email__c = contactIdWithEmailAddMap.get(contId), 
                                                    rC_Bios__Preferred_Email__c = 'Home'));
            } else {
                contactToUpdate.add(new Contact(Id = contId, rC_Bios__Home_Email__c = NULL, 
                                                    rC_Bios__Preferred_Email__c = NULL));
            }
        }
        if( contactToUpdate.size() > 0 )
            update contactToUpdate;
    }

    /*
*
*Method markedFirstEmailPrimary
*This is to update first email
*on contact to set primary equals to true.
*
*/
    public static void markedFirstEmailPrimary(set<Id> setContactIds, Map<Id,list<Email__c>> mapContactemails){


        if(mapContactemails != null && mapContactemails.size()>0){
            // remove all entries which already has Primary__c true in email records
            for(String str:setContactIds){
                mapContactemails.remove(str);
            }

            if(mapContactemails != null && mapContactemails.size()>0){

                for(Contact con : [SELECT Id,rC_Bios__Home_Email__c FROM Contact Where Id IN: mapContactemails.keyset() AND rC_Bios__Home_Email__c =NULL]){

                    if(mapContactemails.containsKey(con.Id)){
                        //to get the list of emails for the contact.
                        list<Email__c> firstemail = mapContactemails.get(con.Id);

                        if(firstemail != null && firstemail.size()>0){
                            //first email on contact are marked as preferred.
                            Email__c objemail = firstemail.get(0);
                            objemail.Primary__c=true;
                        }
                    }
                }
            }
        }
    }

    /*public static void setPrimaryEmailOnContact(Map<Id,String> mapOfContactIdsVsEmailAddresss) {
        List<Contact> listOfContacts = new List<Contact>();
        Map<Id, Email__c> contactIdWithEmailRecordMap = new Map<Id, Email__c>();
        Contact contRecord;
        for( Email__c em: [Select Id,  Email_address__c, Contact__c 
                                FROM Email__c 
                                Where ID IN : mapOfContactIdsVsEmailAddresss.keyset() 
                                    AND Primary__c = TRUE]){
            contactIdWithEmailRecordMap.put(em.Contact__c, em);
        }
        for(Id conId : mapOfContactIdsVsEmailAddresss.keyset() ) {
            contRecord = new Contact();
            contRecord.Id = conId;
            if( contactIdWithEmailRecordMap.containsKey(conId) ){
                contRecord.rC_Bios__Home_Email__c = contactIdWithEmailRecordMap.get(conId).Email_address__c;
                contRecord.rC_Bios__Preferred_Email__c = 'Home';
            } else {
                contRecord.rC_Bios__Home_Email__c = null;
                contRecord.rC_Bios__Preferred_Email__c = null;
            }
            listOfContacts.add(contRecord);
            
        }
        if(!listOfContacts.isEmpty()) {
            try {
                update listOfContacts;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('EmailTriggerHandler','setPrimaryEmailOnContact',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }*/

    public static Map<Id,set<String>> doesContactEmailExist(Map<Id,set<String>> mapOfContactIdPerEmailAddresses){
        Map<Id,set<String>> mapContactHasDuplicate = new Map<Id,set<String>>();
        
        for(Id theContactId : mapOfContactIdPerEmailAddresses.keySet()) {
          if(!mapContactHasDuplicate.containsKey(theContactId)) {
            mapContactHasDuplicate.put(theContactId, new Set<String>());
          }
        }
        
        for(Email__c theEmail : [SELECT Email_address__c, Contact__c FROM Email__c WHERE Contact__c IN : mapOfContactIdPerEmailAddresses.keyset()]) {
            set<String> contactEmailSet = mapOfContactIdPerEmailAddresses.get(theEmail.Contact__c);
            if(contactEmailSet.contains(theEmail.Email_address__c)){
                set<String> emailSet = new set<String>();
                if(mapContactHasDuplicate.containsKey(theEmail.Contact__c)){
                    emailSet = mapContactHasDuplicate.get(theEmail.Contact__c);
                }
                emailSet.add(theEmail.Email_address__c);
                mapContactHasDuplicate.put(theEmail.Contact__c, emailSet);
            }
        }
        return mapContactHasDuplicate; 
    }

    public static void addErrorIfEmailExistsForContact(list<Email__c> incomingEmails){
        Map<Id,set<String>> mapContactId_EmailSet = new Map<Id,set<String>>();
        for(Email__c theEmail : incomingEmails) {
            set<String> emailSet = new set<String>();
            if(mapContactId_EmailSet.containsKey(theEmail.Contact__c)){
                emailSet = mapContactId_EmailSet.get(theEmail.Contact__c);
            }
            emailSet.add(theEmail.Email_address__c);
            mapContactId_EmailSet.put(theEmail.Contact__c, emailSet);
        }
        Map<Id,set<String>> resultsMap = doesContactEmailExist(mapContactId_EmailSet);
        for(Email__c theEmail : incomingEmails) {
            if(resultsMap.containsKey(theEmail.Contact__c)){
                if(resultsMap.get(theEmail.Contact__c).contains(theEmail.Email_address__c)){
                    theEmail.addError('EMAIL ADDRESS ALREADY EXISTS FOR THIS CONTACT.');
                }
            }
        }
    }
    
    /*
    * Method handleUndeliverable
    * Per ZD-57283 
    * If status changed to a designate undeliverable status, set Undeliverable to true
    * If Undeliverable set to true and Undeliverable Date unsert, set Undeliverable Date
    * If Undeliverable set to true but status is not a designated undeliverable status, throw error
    * If Undeliverable set to false but status is set to a designated undeliverable status, throw error
    */
    @TestVisible private static void handleUndeliverable(Email__c em, Email__c oldEm) {
        if (em.Undeliverable__c == FALSE && oldEm.Undeliverable__c == TRUE && UNDELIVERABLE_STATUSES.contains(em.Email_Status__c)) {
            Trigger.new[0].addError(System.Label.EMAIL_DELIVERABLE_INVALID_STATUS);
        }
        if (em.Email_Status__c != oldEm.Email_Status__c && UNDELIVERABLE_STATUSES.contains(em.Email_Status__c)) {
            em.Undeliverable__c = TRUE;
            // Mark primary email to false
              // Modified by :: roundCorner Inc. :: 14-Jan-2019
              // Zendesk: #57475
            em.Primary__c  = false;
            
        }
        if (em.Email_Status__c != oldEm.Email_Status__c && !UNDELIVERABLE_STATUSES.contains(em.Email_Status__c)) {
            em.Undeliverable__c = FALSE;
        }
        if (em.Undeliverable__c == TRUE && oldEm.Undeliverable__c == FALSE && em.Undeliverable_Date__c == NULL) {
            if (!UNDELIVERABLE_STATUSES.contains(em.Email_Status__c)) {
                Trigger.new[0].addError(System.Label.EMAIL_UNDELIVERABLE_INVALID_STATUS);
            }
            em.Undeliverable_Date__c = Date.Today();
        }
        if (em.Undeliverable__c == TRUE && oldEm.Undeliverable__c == TRUE && em.Undeliverable_Date__c == NULL) {
             em.Undeliverable_Date__c = Date.Today();
        }
    }
    

}
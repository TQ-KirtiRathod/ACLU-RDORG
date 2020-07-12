/*
*
*Name  :  PhoneTriggerHandler
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 14, 2016
*Purpose : Handler class for PhoneTrigger. Includes trigger operations for insert/update/delete case. 
*          Contains methods to ensure a single Phone record is marked as Primary and set Primary Phone on contact.
* Made changes by RC - ZenDesk(#65473) 
*/
public class PhoneTriggerHandler {

    public static list<Phone__c> listPhone;
    public static list<AsyncRequest__c> newAsyncRequest = new list<AsyncRequest__c>();
    public static double phoneAsyncBatchMax;
    public static Boolean skipTrigger = False;
    
  static {
        Queueable_Control__c qc = Queueable_Control__c.getInstance('MainQueueable');
        
        if (qc != null) {
            phoneAsyncBatchMax = qc.Batch_Size_Phone__c;
        } else {
            phoneAsyncBatchMax = 100;
        }
    }
    
    public static void mainEntry(List<Phone__c> newList, List<Phone__c> oldList, 
                    Map<Id,Phone__c> newMap, Map<Id,Phone__c> oldMap, Boolean isInsert, 
                    Boolean isUpdate, Boolean isDelete, Boolean isUndelete, 
                    Boolean isBefore, Boolean isAfter) {

        //if trigger is active
        if(TriggerState.isActive('Phone_Trigger') 
            && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) 
            && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {
            // It is called on before insert
            if(isBefore) {
                if(isInsert) {
                   onBeforeInsert(newList);
                }
            }

            // It is called on before update
            if(isBefore) {
                if(isUpdate) {
                    onBeforeUpdate(newList, oldMap);
                }
                if(isDelete) {
                    beforeDelete(oldList);
                }
            }
         }
    }

    /*
    *
    *Method to preform updates on Before Insert Event
    *@param : newList
    *
    */
    public static void onBeforeInsert(List<Phone__c> newList) {
        Map<Id,list<Phone__c>> mapContactPhones = new Map<Id,list<Phone__c>>();
        Set<Id> setContactIds = new Set<Id>();
        Map<Id,String> mapOfContactIdAndPhoneNumber = new Map<Id,String>();
        set<Id> uniqueContactIds = new Set<Id>();

        for(Phone__c pn : newList) {
            // Used for populating External Id  (preventDuplicatePhoneRecord)
            //pn.Active__c = true;//Commented by Bhavesh:I-312328
            //pn.External_Id__c = String.valueOf(pn.Contact__c).Substring(0,15)+'_'+pn.Phone_Number__c.replaceAll('[^0-9]','');

            //check for phone's preferred and if its contact is not null
            if(pn.IsPrimary__c != true && pn.Contact__c != null) {
                 mapContactPhones.put(pn.Contact__c,new list<Phone__c>());
                 mapContactPhones.get(pn.Contact__c).add(pn);
            }

            //If for the same contact another phone's preferred is true
            //the contact is stored in setContactIds.
            else if(pn.IsPrimary__c == true && mapContactPhones.containsKey(pn.Contact__c)) {
                setContactIds.add(pn.Contact__c);
            }
            
            if(pn.IsPrimary__c == TRUE && pn.Contact__c != null && pn.Phone_Number__c != null) {
              mapOfContactIdAndPhoneNumber.put(pn.Contact__c,pn.Phone_Number__c);    
            }
            
            // marks a single phone as Primary
            if(pn.IsPrimary__c == TRUE && pn.Contact__c != null && !uniqueContactIds.contains(pn.Contact__c)){
              UniquecontactIds.add(pn.Contact__c);
              mapOfContactIdAndPhoneNumber.put(pn.Contact__c,pn.Phone_Number__c);
            }
            else if(pn.IsPrimary__c == TRUE && pn.Contact__c != null && uniqueContactIds.contains(pn.Contact__c)) { 
              pn.IsPrimary__c = FALSE;
            }
            //ZenDesk - (#65473) 
            if(pn.Phone_Status__c != null
               && pn.Phone_Status__c.equalsIgnoreCase('Invalid')
               && pn.Invalid_date__c == null) {
                pn.Invalid_date__c = System.today();
            } 
            if(pn.Universal_SMS_Opt_Out__c && pn.Universal_SMS_Opt_Out_Date__c == null) {
                pn.Universal_SMS_Opt_Out_Date__c = System.today();
            }
            //ZenDesk - END (#65473)
        }

        //markedFirstPhonePrimary(mapContactPhones, setContactIds);
        
        if(!uniqueContactIds.IsEmpty()){
          markSinglePhoneRecodAsPrimary(uniqueContactIds, null);
        }
        
        if(mapOfContactIdAndPhoneNumber != null && !(System.isBatch() || System.isFuture())) {
          Id setPrimaryPhoneJobId = System.enqueueJob(new QueueSetPrimaryPhoneOnContact(mapOfContactIdAndPhoneNumber));     
        }
    }

    /*
    *
    *Method to preform updates on Before Update Event
    *@param : newList, mapOldPhones
    *
    */
    public static void onBeforeUpdate(List<Phone__c> newList, Map<Id,Phone__c> mapOldPhones) {
        Map<Id,String> mapOfContactIdAndPhoneNumber = new Map<Id,String>();
        Set<Id> uniqueContactIds = new Set<Id>();
        Set<Id> phoneIds = new Set<Id>();
        for(Phone__c pn : newList) {
            // Used for populating External Id  (preventDuplicatePhoneRecord)
            //pn.Active__c = true;//Commented by Bhavesh:I-312328
            //pn.External_Id__c = String.valueOf(pn.Contact__c).Substring(0,15)+'_'+pn.Phone_Number__c.replaceAll('[^0-9]','');
            
          if(pn.IsPrimary__c == TRUE 
            && pn.Contact__c != null && pn.Phone_Number__c != null 
            && mapOldPhones.get(pn.Id).IsPrimary__c == False && !uniqueContactIds.contains(pn.contact__c)){
             mapOfContactIdAndPhoneNumber.put(pn.Contact__c,pn.Phone_Number__c);
             uniqueContactIds.add(pn.Contact__c);
          } else if(pn.IsPrimary__c == FALSE 
                && pn.Contact__c != null && pn.Phone_Number__c != null 
                && mapOldPhones.get(pn.Id).IsPrimary__c == TRUE && !uniqueContactIds.contains(pn.contact__c)){
              mapOfContactIdAndPhoneNumber.put(pn.Contact__c,'');
              uniqueContactIds.add(pn.Contact__c);
          }
          else if(uniqueContactIds.contains(pn.contact__c)){
             pn.IsPrimary__c = FALSE;
          }
		//ZenDesk - (#65473) 
		  if(pn.Phone_Status__c != null
          && pn.Phone_Status__c.equalsIgnoreCase('Invalid')
          && pn.Invalid_date__c == null) {
			pn.Invalid_date__c = System.today();
          }
          if(pn.Universal_SMS_Opt_Out__c && pn.Universal_SMS_Opt_Out_Date__c == null) {
                pn.Universal_SMS_Opt_Out_Date__c = System.today();
          }
          //ZenDesk - END (#65473) 
            
          phoneIds.add(pn.Id);
          
          
        }
        
        if(!uniqueContactIds.IsEmpty() && !skipTrigger){
          markSinglePhoneRecodAsPrimary(uniqueContactIds, phoneIds);
        } 
        
        if(mapOfContactIdAndPhoneNumber!= null && !skipTrigger && !(System.isBatch() || System.isFuture())) {
          Id setPrimaryPhoneJobId = System.enqueueJob(new QueueSetPrimaryPhoneOnContact(mapOfContactIdAndPhoneNumber));     
        }
        
    }
    
    public static void beforeDelete( List<Phone__c> oldList ){
        List<Id> contactIds = new List<Id>();
        Map<Id, String> contactIdWithEmailAddMap = new Map<Id, String>();
        List<Contact> contactToUpdate = new List<Contact>();
        for(Phone__c phn : oldList){
            if(phn.IsPrimary__c == TRUE)
                contactIds.add( phn.contact__c );
        }
        for( Phone__c phn: [Select id, contact__c, Phone_Number__c 
                            FROM Phone__c 
                                where Contact__c in: contactIds 
                                    AND IsPrimary__c = TRUE
                                    AND Id Not IN: oldList]){
            contactIdWithEmailAddMap.put( phn.Contact__c, phn.Phone_Number__c );
        }
        for( Id contId : contactIds ){
            if( contactIdWithEmailAddMap.containsKey(contId)){
                contactToUpdate.add(new Contact(Id = contId, HomePhone = contactIdWithEmailAddMap.get(contId), 
                                                    rC_Bios__Preferred_Phone__c = 'Home'));
            } else {
                contactToUpdate.add(new Contact(Id = contId, HomePhone = NULL, 
                                                    rC_Bios__Preferred_Phone__c = NULL));
            }
        }
        if( contactToUpdate.size() > 0 )
            update contactToUpdate; 
    }
    
    
    /*public static void AfterInsert(List<Phone__c> newList) {
      list<Id> idsForAsync_Phone = new list<Id>();
      
      for(Phone__c pn : newList) {
        if(pn.IsPrimary__c == TRUE && pn.Contact__c != null && pn.Phone_Number__c != null){
          idsForAsync_Phone.add(pn.Id);
        }    
      }

       // Controls the number of Ids passed into a single AsyncRequest__c record for async processing
      if(idsForAsync_Phone.size() > phoneAsyncBatchMax){

        newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='phone_primarySet', Object_API_Name__c = 'Phone__c',
                                    Params__c = String.join(idsForAsync_Phone,',')));
        idsForAsync_Phone.clear();
      }
          
      // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
        if(idsForAsync_Phone.size() > 0){
          newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='phone_primarySet', Object_API_Name__c = 'Phone__c',
                                    Params__c = String.join(idsForAsync_Phone,',')));
          try {
            insert newAsyncRequest;
          } catch(Exception ex){
            // or suggest using our ApexLog Asset to record the fail!
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('PhoneTriggerHandler','AfterInsert',ex.getMessage());
            log.logException(ex);
            log.saveLogs();
          }
        }
    }
    
    public static void AfterUpdate(List<Phone__c> newList, Map<Id,Phone__c> mapOldPhones) {
      list<Id> idsForAsync_Phone = new list<Id>();
      
      for(Phone__c pn : newList) {
        if(pn.IsPrimary__c == TRUE && pn.Contact__c != null && pn.Phone_Number__c != null && mapOldPhones.get(pn.Id).IsPrimary__c == False){
          idsForAsync_Phone.add(pn.Id);
        }    
      }

       // Controls the number of Ids passed into a single AsyncRequest__c record for async processing
      if(idsForAsync_Phone.size() > phoneAsyncBatchMax){
        newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='phone_primarySet', Object_API_Name__c = 'Phone__c',
                                    Params__c = String.join(idsForAsync_Phone,',')));
        idsForAsync_Phone.clear();
      }
          
      // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
      if(idsForAsync_Phone.size() > 0){
        newAsyncRequest.add( new AsyncRequest__c(
                                AsyncType__c ='phone_primarySet', Object_API_Name__c = 'Phone__c',
                                Params__c = String.join(idsForAsync_Phone,',')));
        try {
          insert newAsyncRequest;
        } catch(Exception ex){
          // or suggest using our ApexLog Asset to record the fail!
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('PhoneTriggerHandler','AfterUpdate',ex.getMessage());
            log.logException(ex);
            log.saveLogs();
        }
      }  
    }
    */
    
    /*
     Update single Phone single record to be Primary 
    */
    
    public static void markSinglePhoneRecodAsPrimary(Set<Id> contactIds, set<Id>phoneIds){
    List<Phone__c> updatePhones = new List<Phone__c>();
    String Query = 'SELECT Id FROM Phone__c WHERE Contact__c =: contactIds';
    
    if(phoneIds != null){
      Query= Query+ ' AND Id !=: phoneIds';
    }
      
     for(Phone__c objPhone: Database.query(query)){
        objPhone.isPrimary__c = false;
        updatePhones.add(objPhone);
     }
     if(!updatePhones.IsEmpty()){
          skipTrigger = true;
        update updatePhones;
        skipTrigger = false;
     }
    }
    

    /*
    *
    *Method markedFirstPhonePrimary
    *This is to update first Phone
    *on contact to set primary equals to true.
    *
    */
 /*   public static void markedFirstPhonePrimary(Map<Id,list<Phone__c>> mapContactPhones,Set<Id> setContactIds){

            if(mapContactPhones != null && mapContactPhones.size()>0) {

                // remove all entries which already has Primary__c true in phone records
                for(String str : setContactIds) {
                    mapContactPhones.remove(str);
                }

                if(mapContactPhones != null && mapContactPhones.size()>0) {
                    for(Contact con : [SELECT Id,HomePhone FROM Contact Where Id IN: mapContactPhones.keyset() AND HomePhone = NULL]) {
                         if(mapContactPhones.containsKey(con.Id)) {
                            //to get the list of phones for the contact.
                            list<Phone__c> phonesList = mapContactPhones.get(con.Id);
                            if(phonesList != null && phonesList.size()>0) {
                                 //first phone on contact are marked as preferred.
                                 Phone__c objPhone = phonesList.get(0);
                                 objPhone.IsPrimary__c=true;
                            }
                         }
                    }
                }
            }
        }*/

    // DS 2019-08-21 removed @future; converted to queueable
    public static void setPrimaryPhoneOnContact(Map<Id,String> mapOfContactIdsVsPhoneNumber) {
        List<Contact> listOfContacts = new List<Contact>();
        for(Contact theContact : [SELECT Id, rC_Bios__Preferred_Phone__c,HomePhone 
                                    FROM Contact 
                                    WHERE Id IN : mapOfContactIdsVsPhoneNumber.keySet()]) {
            Boolean updatedContact = false;
            System.debug(' theContact.HomePhone+++++++++++++++++++++++++'+ theContact.HomePhone);
            System.debug(' theContact.rC_Bios__Preferred_Phone__c+++++++'+ theContact.rC_Bios__Preferred_Phone__c);
            if( mapOfContactIdsVsPhoneNumber.get(theContact.Id) == ''){
                if ( theContact.HomePhone != null && theContact.rC_Bios__Preferred_Phone__c != null ) {
                    theContact.HomePhone = NULL;
                    theContact.rC_Bios__Preferred_Phone__c = NULL;
                    updatedContact = true;
                }
            } else {
                theContact.HomePhone = mapOfContactIdsVsPhoneNumber.get(theContact.Id);
                if ( theContact.rC_Bios__Preferred_Phone__c != 'Home') {
                    theContact.rC_Bios__Preferred_Phone__c = 'Home';
                    updatedContact = true;
                }
            }
            if (updatedContact) {
                listOfContacts.add(theContact);
            }
        }
        if(!listOfContacts.isEmpty()) {
            update listOfContacts;        
        }
    }

    public class QueueSetPrimaryPhoneOnContact implements Queueable {
        Map<Id,String> mapOfContactIdsVsPhoneNumber;
        public QueueSetPrimaryPhoneOnContact(Map<Id,String> mapOfContactIdsVsPhoneNumber) {
            this.mapOfContactIdsVsPhoneNumber = mapOfContactIdsVsPhoneNumber;
        }
        public void execute(QueueableContext context) {
            setPrimaryPhoneOnContact(mapOfContactIdsVsPhoneNumber);
        }
    }
 }
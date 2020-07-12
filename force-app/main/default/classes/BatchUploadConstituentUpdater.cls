/*
*
*Name  :  BatchUploadConstituentUpdater
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 03, 2016
*Purpose :  BatchUploadConstituentUpdater creates Email and Phone record if Batch Upload record is coming in from online source.  
            Class is called from the BatchUploadHandler.
*
*/
public without sharing class BatchUploadConstituentUpdater {

  /*
  *
  *Method createEmailRecord
  *@param : newBatchUpload(new list of batch upload)
  *if rC_Connect__Batch_Upload_Contact_1_Matched__c is not null
  *and Contact1_Email is also not null
  *It will then create a new Email object record
  *for every online incoming batch upload
  *It will create a new Email object record.
  *
  */
  public static void createEmailRecord( map<String, rC_Connect__Batch_Upload__c> mapBatches) {

    map<Email__c, String> mapEmailPref =  new map<Email__c, String>();
    map<string, Email__c> mapEmails = new  map<string, Email__c>();
    map<String, String> mapAdditionalList = new map<String, String>();
    Map<Id, set<String>> mapContactHasDuplicate = new Map<Id, Set<String>>();
    Set<String> setExistingId = new Set<String>();
    List<rC_Connect__Batch_Upload__c> createBatchEmail = new List<rC_Connect__Batch_Upload__c>();
    Map<String, rC_Connect__Batch_Upload__c> mapBatchOpt = new Map<String, rC_Connect__Batch_Upload__c>();

    if (mapBatches != null && mapBatches.size() > 0) {

      Map<Id, Set<String>> mapOfContactIdAndEmailAddresses = new Map<Id, Set<String>>();

      for (String key : mapBatches.keySet()) {
        String contactId = key.length() >= 15 && key.startsWith('003') ? key.subString(0, 15) : '';
        String emailAddress = contactId != '' && key.contains('_') && (key.subString(15, key.length())).length() > 1
                              ? key.subString(16, key.length()) : '';
        if (contactId != '' && (!mapOfContactIdAndEmailAddresses.containsKey(contactId))) {
          mapOfContactIdAndEmailAddresses.put(contactId, new Set<String>());
        }
        if (emailAddress != '') {
          mapOfContactIdAndEmailAddresses.get(contactId).add(emailAddress);
        }
      }

      if (mapOfContactIdAndEmailAddresses != null) {
        mapContactHasDuplicate = EmailTriggerHandler.doesContactEmailExist(mapOfContactIdAndEmailAddresses);
      }

      for (String externalId : mapBatches.keyset()) {
        String contactId = externalId.length() >= 15 && externalId.startsWith('003') ? externalId.subString(0, 15) : '';
        String emailAddress = contactId != '' && externalId.contains('_')
                              && (externalId.subString(15, externalId.length())).length() > 1
                              ? externalId.subString(16, externalId.length()) : '';
        if (mapContactHasDuplicate.containsKey(contactId) && (! (mapContactHasDuplicate.get(contactId).contains(emailAddress)) ) ) {
          // Create Email record
          rC_Connect__Batch_Upload__c objBtu = mapBatches.get(externalId);
          Email__c objEmail = createEmail(mapBatches.get(externalId));
          mapEmails.put(externalId, objEmail);
          mapAdditionalList.put(externalId, objBtu.Additional_Opt_In_Lists__c);

        } else if (mapContactHasDuplicate.containsKey(contactId) && (mapContactHasDuplicate.get(contactId).contains(emailAddress)) ) {
          if (mapBatches.get(externalId).Cont1_OptIn__c && !setExistingId.contains(externalId)) {
            setExistingId.add(externalId);
            mapBatchOpt.put(externalId, mapBatches.get(externalId));
            createBatchEmail.add(mapBatches.get(externalId));
          }
        }
      }

      if (mapEmails != null && mapEmails.size() > 0) {
        try {
          insert mapEmails.values();
          if (Test.isRunningTest())
            Integer i = 10 / 0;
        } catch (Exception e) {
          apexLogHandler.apexLog log =
            new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '', 'createEmailRecord error:  '+e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
        for (String externalId : mapEmails.keySet()) {
          if (mapAdditionalList.containsKey(externalId)) {
            mapEmailPref.put(mapEmails.get(externalId), mapAdditionalList.get(externalId));
          }
        }
      }
      if (mapEmailPref != null && mapEmailPref.size() > 0) {
        createEmailPrefrences(mapEmailPref, false, mapBatches, false);
      }
      if (setExistingId != null && !setExistingId.IsEmpty()) {
        updateEmailRecord(setExistingId, createBatchEmail, mapBatchOpt);
      }
    }
  }

  /*
  *Method updateEmailRecord
  *@param : newBatchUpload(new list of batch upload)
  *@param : mapBatchUpload
  *if rC_Connect__Batch_Upload_Contact_1_Matched__c is not null
  *and Contact1_Email is also not null
  *It will update the email object on batch upload
  *if email+contactid exist on email record and if its contact optIn is Changed.
  *if it doesn't exist it will create a new email record.
  *While updating batch upload, if additional pref list are newly added
  *it will also then create an Email preference on existing code
  *
  */
  public static void updateEmailRecord(set<String> setExistingId, list<rC_Connect__Batch_Upload__c> createBatchEmail, 
                                        map<String, rC_Connect__Batch_Upload__c> mapBatchOpt) {

    set<String> setExistCodes = new set<String>();
    list<Email__c> listEmail = new list<Email__c>();
    list<Email_Preference__c> listEmailPrefsUpdate = new list<Email_Preference__c>();
    list<rC_Connect__Batch_Upload__c> listBatchCreate = new list<rC_Connect__Batch_Upload__c>();
    map<String, list<String>> mapEmails = new map<String, list<String>>();
    map<Email__c, String> mapCreateAnotherPref = new map<Email__c, String>();
    map<String, String> mapBatchProcess = new map<String, String>();
    map<string, Email__c> mapEmailsNew = new  map<string, Email__c>();
    map<String, String> mapAdditionalLists = new map<String, String>();
    map<Email__c, String> mapEmailPrefs =  new map<Email__c, String>();
    map<Email__c, String> mapEmailAdd = new map<Email__c, String>();
    map<Email__c, Boolean> mapEmailvsEmailUpdated = new map<Email__c, Boolean>();
    Set<Id> contactIds = new Set<Id>();
    Set<String> emailAddresses = new Set<String>();
    Map<Id, Set<String>> mapOfContactIdAndEmailAddresses = new Map<Id, Set<String>>();
    Map<Id, Set<String>> mapContactHasDuplicate = new Map<Id, Set<String>>();
    Map<String, Email_Preference_List__c> mapGetListCode = new map<String, Email_Preference_List__c>();
    Set<String> existingAddEmailPrefs = new Set<String>();
    map<String, Email_Preference_List__c> getAllEmailPref = Email_Preference_List__c.getAll();
    for (Email_Preference_List__c epl : getAllEmailPref.values()) {
      mapGetListCode.put(epl.List_Code__c, epl);
    }
    List<Email_Preference__c> listOfEmailPreferences = new List<Email_Preference__c>();

    for (String key : setExistingId) {
      String contactId = key.length() >= 15 && key.startsWith('003') ? key.subString(0, 15) : '';
      String emailAddress = contactId != '' && key.contains('_') && (key.subString(15, key.length())).length() > 1 
                          ? key.subString(16, key.length()) : '';
      contactIds.add(contactId);
      emailAddresses.add(emailAddress);
      if (contactId != '' && !mapOfContactIdAndEmailAddresses.containsKey(contactId)) {
        mapOfContactIdAndEmailAddresses.put(contactId, new Set<String>());
      }
      if (emailAddress != '') {
        mapOfContactIdAndEmailAddresses.get(contactId).add(emailAddress);
      }
    }

    if (mapOfContactIdAndEmailAddresses != null) {
      mapContactHasDuplicate = EmailTriggerHandler.doesContactEmailExist(mapOfContactIdAndEmailAddresses);
    }

    for (Email__c ema : [SELECT Id, Opt_In__c, Contact__c, External_Id__c, Email_address__c,
                         (SELECT Id, Opt_In__c, Email_List_Code__c, Email__c FROM Email_Preferences__r)
                         FROM Email__c WHERE Contact__c IN: contactIds]) {
      if (emailAddresses.contains(ema.Email_address__c)) {
        String externalId = String.valueOf(ema.Contact__c).subString(0, 15) + '_' + ema.Email_address__c;
        Set<String> setOfAdditionalCodes = new Set<String>();
        if (mapBatchOpt.containsKey(externalId) && (mapBatchOpt.get(externalId).Cont1_OptIn__c)) {
          if (mapBatchOpt.get(externalId).Additional_Opt_In_Lists__c != null) {
            for (String code : mapBatchOpt.get(externalId).Additional_Opt_In_Lists__c.split(',')) {
              setOfAdditionalCodes.add(code);
            }
          }
          if (mapBatchOpt.get(externalId).Cont1_OptIn__c != ema.Opt_In__c) {
            ema.Opt_In__c = mapBatchOpt.get(externalId).Cont1_OptIn__c;
            listEmail.add(ema);
            for (Email_Preference__c ep : ema.Email_Preferences__r) {
              if ((ema.Opt_In__c) && (ep.Opt_In__c != ema.Opt_In__c) 
                  && (setOfAdditionalCodes.contains(ep.Email_List_Code__c) 
                      || ep.Email_List_Code__c == 'ActionNational' 
                      || ep.Email_List_Code__c == 'MemberNational')
              ) {
                ep.Opt_In__c = ema.Opt_In__c;
                listEmailPrefsUpdate.add(ep);
              }
            }
            mapEmailAdd.put(ema, mapBatchOpt.get(externalId).Additional_Opt_In_Lists__c);
          } else {
            for (Email_Preference__c ep : ema.Email_Preferences__r) {
              existingAddEmailPrefs.add(ep.Email_List_Code__c);
              if ((ema.Opt_In__c && ep.Opt_In__c != ema.Opt_In__c) && setOfAdditionalCodes != null 
                  && (setOfAdditionalCodes.contains(ep.Email_List_Code__c))) {
                ep.Opt_In__c = ema.Opt_In__c;
                listEmailPrefsUpdate.add(ep);
              }
            }
            if (setOfAdditionalCodes != null) {
              for (String cd : setOfAdditionalCodes) {
                if (mapGetListCode.containsKey(cd) && (!existingAddEmailPrefs.contains(cd))) {
                  Email_Preference__c ep = new Email_Preference__c(Email__c = ema.Id, Email_List_Code__c = cd, Opt_In__c = true );
                  listOfEmailPreferences.add(ep);
                }
              }
            }
          }
        }
      }
    }

    for (rC_Connect__Batch_Upload__c bps : createBatchEmail) {
      if ((mapContactHasDuplicate.containsKey( String.valueOf(bps.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) ))
          && (!(mapContactHasDuplicate.get( String.valueOf(bps.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) ).contains(bps.Cont1_Email__c)))
         ) {
        String externalId = String.valueOf(bps.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + bps.Cont1_Email__c;
        Email__c email = createEmail(bps);
        mapEmailsNew.put(externalId, email);
        mapAdditionalLists.put(externalId, bps.Additional_Opt_In_Lists__c);
      }
    }

    if (listEmail.size() > 0) {
      try {
        update listEmail;
        if (Test.isRunningTest())
          Integer i = 10 / 0;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '',
                                                                'updateEmailRecord listEmail error::  '+e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }
    if (listEmailPrefsUpdate.size() > 0) {
      try {
        update listEmailPrefsUpdate;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '',
                                                    'updateEmailRecord listEmailPrefsUpdate error::  '+ e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }
    if (mapEmailsNew != null && mapEmailsNew.size() > 0) {
      try {
        insert mapEmailsNew.values();
        if (Test.isRunningTest())
          Integer i = 10 / 0;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '',
                                                            'updateEmailRecord mapEmailsNew error::  '+ e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
      for (String externalId : mapEmailsNew.keySet()) {
        if (mapAdditionalLists.containsKey(externalId)) {
          mapEmailPrefs.put(mapEmailsNew.get(externalId), mapAdditionalLists.get(externalId));
        }
      }
    }

    if (listOfEmailPreferences.size() > 0) {
      try {
        insert listOfEmailPreferences;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '',
                                                 'updateEmailRecord listOfEmailPreferences error::  '+  e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }

    if (mapEmailPrefs != null && mapEmailPrefs.size() > 0) {
      createEmailPrefrences(mapEmailPrefs, false, mapBatchOpt, false);
    }

    if (mapEmailAdd != null && mapEmailAdd.size() > 0) {
      createEmailPrefrences(mapEmailAdd, true, mapBatchOpt, true);
    }

  }

  /*
  *
  *Method createEmail
  *@param : rC_Connect__Batch_Upload__c(new batch upload)
  *It is used for creating email Record
  *
  */
  public static Email__c createEmail(rC_Connect__Batch_Upload__c btup) {

    Email__c em = new Email__c();
    em.Contact__c = btup.rC_Connect__Batch_Upload_Contact_1_Matched__c;
    if (btup.rC_Connect__Giving_Record_Type__c == 'Donation') {
      em.Primary__c = true;
    }

    em.Email_address__c = btup.Cont1_Email__c;
    em.Email_Type__c = btup.Cont1_EmailType__c;
    em.Opt_In__c = btup.Cont1_OptIn__c;
    em.Acquisition__c = btup.SB_Acquisition__c;
    em.Acquisition_Market_source__c = btup.SB_Acquisition_Market_source__c;
    em.Acquisition_Initial_market_source__c = btup.SB_Acquisition_Initial_market_source__c;
    em.Acquisition_Initial_Referral_URL__c = btup.SB_Acquisition_Initial_Referral_URL__c;
    em.Acquisition_Referral_URL__c = btup.SB_Acquisition_Referral_URL__c;
    em.Acquisition_Form_ID__c = btup.SB_Acquisition_Form_ID__c;
    em.Acquisition_Form_URL__c = btup.SB_Acquisition_Form_URL__c;
    em.Acquisition_Form_Internal_Name__c = btup.SB_Acquisition_Form_Internal_Name__c;
    em.Acquisition_Upload_source__c = btup.SB_Acquisition_Upload_source__c;
    em.Acquisition_Date__c = btup.SB_Acquisition_Date__c;
    em.Acquisition_Campaign__c = btup.SB_Acquisition_Campaign__c;
    em.Acquisition_Market_Source_Channel__c = btup.SB_Acquisition_Market_Source_Channel__c;
    em.Acquisition_Market_Source_Affiliation__c = btup.SB_Acquisition_Market_Source_Affiliation__c;
    em.Acquisition_Market_Source_Other__c = btup.SB_Acquisition_Market_Source_Other__c;
    em.Acquisition_Market_Source_External__c = btup.SB_Acquisition_Market_Source_External__c;
    em.Acquisition_Initial_Market_SourceChannel__c  = btup.SB_Acquisition_Initial_Mkt_Source_Chan__c;
    em.Acquisition_Initial_Market_Source_Affi__c = btup.SB_Acquisition_Initial_Mkt_Source_Affi__c;
    em.Acquisition_Initial_Market_Source_Other__c = btup.SB_Acquisition_Initial_Mkt_Source_Othe__c;
    em.Acquisition_Initial_Market_Source_Extern__c  = btup.SB_Acquisition_Initial_Mkt_Source_Exte__c;
    em.Acquisition_Search_Engine__c = btup.SB_Acquisition_Search_Engine__c;
    em.Acquisition_Search_String__c = btup.SB_Acquisition_Search_String__c;
    em.Acquisition_User_Agent__c = btup.SB_Acquisition_User_Agent__c;
    em.Acquisition_Device_Type__c = btup.SB_Acquisition_Device_Type__c;
    em.Acquisition_Device_Name__c = btup.SB_Acquisition_Device_Name__c;
    em.Acquisition_Device_OS__c = btup.SB_Acquisition_Device_OS__c;
    em.Acquisition_Device_Browser__c = btup.SB_Acquisition_Device_Browser__c;
    em.Acquisition_Social_Referrer_Transaction__c = btup.SB_Acquisition_Social_Referrer_Transact__c;
    return em;
  }


  /*
  *
  *Method createEmailPrefrences
  *@Param : mapEmailPref
  *@param : isUpdate
  *When Opt-In on Email is set to True
  *It will by default create two emails pref
  *one for ActionNational and other for MembershipNational
  *and also one for HomeAffiliate.
  *if batch upload consist some code values it also creates an
  *Email Pref related to that email
  *
  */
  public static void createEmailPrefrences(map<Email__c, String> mapEmailPref, 
                                           boolean isUpdate, map<String, 
                                           rC_Connect__Batch_Upload__c> mapBatches, 
                                           Boolean UpdateEmailPref) {
    map<String, Email_Preference_List__c> mapGetListCode = new map<String, Email_Preference_List__c>();
    map<String, List<Email_Preference__c>> mapOfEmailVsAdditionalPreferences = new map<String, List<Email_Preference__c>>();
    map<String, List<Email_Preference__c>> mapOfEmailIdVsAllEmailPrefs = new map<String, List<Email_Preference__c>>();
    list<Email_Preference__c> listEmailPref = new list<Email_Preference__c>();
    map<String, list<Email__c>> mapEmails = new map<String, list<Email__c>>();
    map<String, set<String>> mapEmailIdToExistingPref = new map<String, set<String>>();
    map<Id, list<Email__c>> mapHomeAffiliate = new map<Id, list<Email__c>>();
    Set<String> setOfZipCodes = new Set<String>();
    Map<String, Zip_Affiliate__c> mapOfZipVsZipAffiliate = new Map<String, Zip_Affiliate__c>();
    map<String, List<Email_Preference_List__c>> mapEmailPrefList = new map<String, List<Email_Preference_List__c>>();
    map<String, Email_Preference_List__c> getAllEmailPref = Email_Preference_List__c.getAll();
    for (Email_Preference_List__c epl : getAllEmailPref.values()) {
      mapGetListCode.put(epl.List_Code__c, epl);
    }
    for (Email_Preference_List__c epl : [SELECT Affiliation__c, Is_Home_Affiliate_List__c, List_Code__c, List_Label__c
                                         FROM Email_Preference_List__c
                                         WHERE Is_Home_Affiliate_List__c = true]) {
      if (!mapEmailPrefList.containsKey(epl.Affiliation__c)) {
        mapEmailPrefList.put(epl.Affiliation__c, new List<Email_Preference_List__c>());
      }
      mapEmailPrefList.get(epl.Affiliation__c).add(epl);
    }

    for (rC_Connect__Batch_Upload__c bu : mapBatches.values()) {
      if (bu.rC_Connect__Address_Postal_Code__c != null && (bu.rC_Connect__Address_Postal_Code__c.length() >= 5)) {
        setOfZipCodes.add((bu.rC_Connect__Address_Postal_Code__c).subString(0, 5));
      }
    }

    for (Zip_Affiliate__c zipAffiliate : [SELECT Id, Name, Affiliation__c 
                                          FROM Zip_Affiliate__c 
                                          WHERE Name IN: setOfZipCodes and Affiliation__c != null]) {
      mapOfZipVsZipAffiliate.put(zipAffiliate.Name, zipAffiliate);
    }

    for (Email__c objEmail : mapEmailPref.keyset()) {
      set<String> setExistingEmails = new set<String>();

      if (isUpdate) {
        for (Email_Preference__c emp : objEmail.Email_Preferences__r) {

          setExistingEmails.add(emp.Email_List_Code__c);
          if (!mapOfEmailIdVsAllEmailPrefs.containsKey(emp.Email__c)) {
            mapOfEmailIdVsAllEmailPrefs.put(emp.Email__c, new List<Email_Preference__c>());
          }
          mapOfEmailIdVsAllEmailPrefs.get(emp.Email__c).add(emp);
        }

        mapEmailIdToExistingPref.put(objEmail.id, setExistingEmails) ;
      }

      if (objEmail.Opt_In__c == true) {
        set<String> setOfCodes = new set<String>();

        if (!setExistingEmails.contains('ActionNational')) {
          Email_Preference__c actionNational = new Email_Preference__c();
          actionNational.Email__c = objEmail.Id;
          actionNational.Email_List_Code__c = 'ActionNational';
          actionNational.Opt_In__c = true;
          setExistingEmails.add('ActionNational');
          listEmailPref.add(actionNational);
        }

        if (!setExistingEmails.contains('MemberNational')) {
          Email_Preference__c memberNational = new Email_Preference__c();
          memberNational.Email__c = objEmail.Id;
          memberNational.Email_List_Code__c = 'MemberNational';
          memberNational.Opt_In__c = true;
          setExistingEmails.add('MemberNational');
          listEmailPref.add(memberNational);
        }

        // Creation of Home Affiliates
        String externalId = String.valueOf(objEmail.Contact__c).Substring(0, 15) + '_' + objEmail.Email_address__c;
        if ((mapBatches.containsKey(externalId)) && (mapBatches.get(externalId) != null)) {
          if ((mapBatches.get(externalId).rC_Connect__Address_Postal_Code__c != null) 
              && ((mapBatches.get(externalId).rC_Connect__Address_Postal_Code__c).length() >= 5) 
              && (mapOfZipVsZipAffiliate.containsKey(((mapBatches.get(externalId).rC_Connect__Address_Postal_Code__c).subString(0, 5)))) 
          ) {
            String zip = (mapBatches.get(externalId).rC_Connect__Address_Postal_Code__c).subString(0, 5);
            if (!mapEmails.containsKey(zip)) {
              mapEmails.put(zip, new list<Email__c>());
            }
            mapEmails.get(zip).add(objEmail);
          } else if (mapBatches.get(externalId).rC_Connect__Batch_Upload_Account_Matched__c != null) {
            String accountId = mapBatches.get(externalId).rC_Connect__Batch_Upload_Account_Matched__c;
            if (!mapHomeAffiliate.containsKey(accountId)) {
              mapHomeAffiliate.put(accountId, new list<Email__c>());
            }
            mapHomeAffiliate.get(accountId).add(objEmail);
          }
        }

        // Creation Of Additional
        if (mapEmailPref.get(objEmail) !=  null) {
          String AdditionalPref = mapEmailPref.get(objEmail);
          for (String code : AdditionalPref.split(',')) {
            if (!setExistingEmails.contains(code)) {
              setOfCodes.add(code);
            }
          }

          for (String cd : setOfCodes) {
            if (mapGetListCode.containsKey(cd)) {
              if (!setExistingEmails.contains(cd)) {
                Email_Preference__c ep = new Email_Preference__c();
                ep.Email__c = objEmail.Id;
                ep.Email_List_Code__c = cd;
                ep.Opt_In__c = true;
                if (!mapOfEmailVsAdditionalPreferences.containsKey(objEmail.Id)) {
                  mapOfEmailVsAdditionalPreferences.put(objEmail.Id, new List<Email_Preference__c>());
                }
                mapOfEmailVsAdditionalPreferences.get(objEmail.Id).add(ep);
              }
            }
          }
        }
      }

    }

    List<Email_Preference__c> updatedEmailPrefList = new List<Email_Preference__c>();
    if (mapEmails != null && mapEmails.size() > 0) {
      if (mapEmails != null && mapEmails.size() > 0) {
        for (Zip_Affiliate__c zipAffiliate : [SELECT Id, Name, Affiliation__c 
                                              FROM Zip_Affiliate__c 
                                              WHERE Name IN: mapEmails.keyset() and Affiliation__c != null]) {
          for (Email__c objem : mapEmails.get(zipAffiliate.Name)) {
            if (mapEmailPrefList.containskey(zipAffiliate.Affiliation__c)) {
              for (Email_Preference_List__c objPref : mapEmailPrefList.get(zipAffiliate.Affiliation__c)) {
                if (!isupdate || (isupdate && mapEmailIdToExistingPref.containsKey(objem.Id) 
                    && !mapEmailIdToExistingPref.get(objem.Id).contains(objPref.List_Code__c))) 
                {
                  Email_Preference__c ep = new Email_Preference__c(Email__c =  objem.Id, Email_List_Code__c = objPref.List_Code__c, Opt_In__c = true);
                  listEmailPref.add(ep);
                  if (!mapEmailIdToExistingPref.containsKey(objem.Id)) {
                    mapEmailIdToExistingPref.put(objem.Id, new Set<String>());
                  }
                  mapEmailIdToExistingPref.get(objem.Id).add(objPref.List_Code__c);
                }
                // For Testing
                if (UpdateEmailPref && isupdate && mapEmailIdToExistingPref.containsKey(objem.Id) 
                    && mapEmailIdToExistingPref.get(objem.Id).contains(objPref.List_Code__c)) {
                  if (mapOfEmailIdVsAllEmailPrefs != null && mapOfEmailIdVsAllEmailPrefs.containsKey(objem.Id)) {
                    for (Email_Preference__c ep : mapOfEmailIdVsAllEmailPrefs.get(objem.Id)) {
                      if (ep.Email_List_Code__c == objPref.List_Code__c && (!ep.Opt_In__c) ) {
                        ep.Opt_In__c = True;
                        updatedEmailPrefList.add(ep);
                      }
                    }
                  }
                }
                // For Testing
              }
            }
          }
        }
      }
    }
    if (mapHomeAffiliate != null && mapHomeAffiliate.size() > 0) {
      Map<String, list<Email__c>> mapOfAffiliationVsEmails = new Map<String, list<Email__c>>();
      for (Account acc : [SELECT Id, Affiliation__c FROM Account WHERE Id IN : mapHomeAffiliate.keySet()]) {
        if (!mapOfAffiliationVsEmails.Containskey(acc.Affiliation__c)) {
          mapOfAffiliationVsEmails.put(acc.Affiliation__c, new list<Email__c>());
        }
        mapOfAffiliationVsEmails.get(acc.Affiliation__c).addAll(mapHomeAffiliate.get(acc.Id));
      }

      for (String aff : mapOfAffiliationVsEmails.keySet()) {
        for (Email__c objem : mapOfAffiliationVsEmails.get(aff)) {
          if (mapEmailPrefList.containskey(aff)) {
            for (Email_Preference_List__c objPref : mapEmailPrefList.get(aff)) {
              if (!isupdate || (isupdate && mapEmailIdToExistingPref.containsKey(objem.Id) 
                  && !mapEmailIdToExistingPref.get(objem.Id).contains(objPref.List_Code__c))) {
                Email_Preference__c ep = new Email_Preference__c(Email__c =  objem.Id, Email_List_Code__c = objPref.List_Code__c, Opt_In__c = true);
                listEmailPref.add(ep);
                if (!mapEmailIdToExistingPref.containsKey(objem.Id)) {
                  mapEmailIdToExistingPref.put(objem.Id, new Set<String>());
                }
                mapEmailIdToExistingPref.get(objem.Id).add(objPref.List_Code__c);
              }
              // For Testing
              if (UpdateEmailPref && isupdate && mapEmailIdToExistingPref.containsKey(objem.Id) 
                  && mapEmailIdToExistingPref.get(objem.Id).contains(objPref.List_Code__c)) {
                if (mapOfEmailIdVsAllEmailPrefs != null && mapOfEmailIdVsAllEmailPrefs.containsKey(objem.Id)) {
                  for (Email_Preference__c ep : mapOfEmailIdVsAllEmailPrefs.get(objem.Id)) {
                    if (ep.Email_List_Code__c == objPref.List_Code__c && (!ep.Opt_In__c) ) {
                      ep.Opt_In__c = True;
                      updatedEmailPrefList.add(ep);
                    }
                  }
                }
              }
              // For Testing
            }
          }
        }
      }
    }

    if (mapOfEmailVsAdditionalPreferences != null && mapOfEmailVsAdditionalPreferences.size() > 0) {
      for (String key : mapOfEmailVsAdditionalPreferences.keyset()) {
        for (Email_Preference__c ep : mapOfEmailVsAdditionalPreferences.get(key)) {
          if (mapEmailIdToExistingPref.containsKey(key) && (!mapEmailIdToExistingPref.get(key).contains(ep.Email_List_Code__c))) {
            listEmailPref.add(ep);
          }
        }
      }
    }

    if (listEmailPref != null && listEmailPref.size() > 0) {
      try {
        insert listEmailPref;
        if (Test.isRunningTest())
          Integer i = 10 / 0;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '', 
                                                       'createEmailPrefrences listEmailPref error::  '+e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }

    if (updatedEmailPrefList != null && updatedEmailPrefList.size() > 0) {
      try {
        update updatedEmailPrefList;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadConstituentUpdater', '',
                                                'createEmailPrefrences updatedEmailPrefList error::  '+ e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }
  }
  /*
  *
  *Method createPhoneRecord
  *@param : newBatchUpload(new list of batch upload)
  *@param : mapBatchUpload(old list of batch upload)
  *rC_Connect__Batch_Upload_Contact_1_Matched__c is not null
  *and rC_Connect__Contact_1_Phone_1__c is also not null
  *It will then create a new Phone object record
  *
  */
  public static void createPhoneRecord(map<String, rC_Connect__Batch_Upload__c> mapPhoneBatches, 
                                       set<Id> setContactIds, 
                                       set<String> setPhone) {

    list<Phone__c> listPhone = new list<Phone__c>();
    set<String> setExistPhone = new set<String>();
    for (Phone__c phones : [SELECT Id, Contact__c, Phone_Number__c 
                            FROM Phone__c 
                            WHERE Contact__c IN: setContactIds]) {
      String externalId = String.valueOf(phones.Contact__c).Substring(0, 15) + '_' + phones.Phone_Number__c.replaceAll('[^0-9]', '');
      if (mapPhoneBatches.containsKey(externalId)) {
        setExistPhone.add(externalId);
      }

    }
    for (rC_Connect__Batch_Upload__c bupn : mapPhoneBatches.values()) {
      if (!setExistPhone.contains(String.valueOf(bupn.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) 
                                    + '_' 
                                    + bupn.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]', ''))
      ) {
        Phone__c pn = new Phone__c();
        if (bupn.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_DONATION 
            || bupn.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_PLEDGE ) {
          pn.IsPrimary__c = true;
        }
        pn.Contact__c = bupn.rC_Connect__Batch_Upload_Contact_1_Matched__c;
        pn.Phone_Number__c = bupn.rC_Connect__Contact_1_Phone_1__c;
        pn.Phone_Type__c = bupn.rC_Connect__Contact_1_Phone_1_Type__c;
        pn.Phone_Status__c = bupn.Cont1_Phone_Status__c;
        pn.SMS_Opt_In__c = bupn.Cont1_SMS_Opt_In__c;
        pn.Mobile_Autodial_Opt_In__c = bupn.Cont1_Mobile_Autodial_Opt_In__c;
        pn.External_ID__c = bupn.rC_Connect__Batch_Upload_Contact_1_Matched__c 
                          + '_' 
                          + bupn.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]', '');

        listPhone.add(pn);
      }
    }

    if (listPhone.size() > 0) {
      List<Database.SaveResult> phoneResults = Database.insert(listPhone,false);
      //create apex logs for error
      Utilities.processResults(phoneResults, listPhone, 'BatchUploadConstituentUpdater', '', 'createPhoneRecord listPhone error::  \n');
    }
  }
}
/*
*
*Name  :  ManageEmailsController
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  December 13, 2016
*Purpose : Controller Class for ManageEmails Page Updates Email Subscriptions (T-561627)
*Changelog : 2018-09 -- BUP Surge code implemented (GH-14)
*/
public without Sharing class ManageEmailsController {
    public String emailAddress{get;set;}
    public String maskEmailAddress {get;set;}
    public Map<String, String> prefLabelsCodeMap{get;set;}
    public Boolean isOptedOut{get;set;}
    public static String isFullOptOt{get;set;}
    public String topSectionText{get;set;}
    public static Integer mapSize{get;set;}
    public Boolean isShowFirstPanel{get;set;}
    public Boolean isShowSecondPanel{get;set;}
    public Map<String, String> allPrefLabelCodeMap;
    public Email__c objEmail;
    public static String emailId;
    public static String referral{get;set;}
    public Map<String, Email_Preference__c> emailPrefCodeMap;
    public Set<String> excludedFromPC;
    public static Map<String, Email_Preference_List__c> emailListSetting ;
    public static Set<String> caListCodes = new Set<String>{'cn','cs','cd'};
    public Boolean surgeProcessing{get;set;}
    public rc_Connect__Batch_Upload__c surgeBUP{get;set;}
    static {
        emailListSetting = Email_Preference_List__c.getAll();
    }

    public static Integer calloutDuration {
        get {
            Integer i;
            String durationString = System.Label.messageStudioCalloutDuration;
            
            try {
                i = Integer.valueOf(durationString);
            } 
            catch (Exception e) {
                System.debug('Error: messageStudioCalloutDuration is not an integer');
                i = 10000;
            }
            return i;
        }
        set;
    }
    
    
    public ManageEmailsController() {
        emailPrefCodeMap = new Map<String, Email_Preference__c>();
        prefLabelsCodeMap = new Map<String, String>();
        allPrefLabelCodeMap = new Map<String, String>();
        excludedFromPC = new Set<String>();
        isOptedOut = false;
        topSectionText = '';
        isShowFirstPanel = false;
        isShowSecondPanel = false;
        emailId = ApexPages.currentPage().getParameters().get('eId');
        referral = ApexPages.currentPage().getParameters().get('referral');
        if(emailListSetting != null) {
            for(Email_Preference_List__c setting : emailListSetting.values()){
                if(setting.Exclude_from_Preference_Center__c) {
                    excludedFromPC.add(setting.List_Code__c);
                }
                allPrefLabelCodeMap.put((setting.List_Code__c).toLowerCase(), setting.List_Label__c);
                if(referral.equalsIgnoreCase(setting.List_Code__c)) {
                    topSectionText = setting.List_Label__c;
                }
            }  
        } 
        
        if(emailId != null && emailId != '') {
        	surgeProcessing = checkForSurge(emailId);
        	if (surgeProcessing) {
	        	List<rc_Connect__Batch_Upload__c> surgeBUPs = [Select Id, Cont1_Email__c, Cont1_Optin__c, rc_Connect__Batch_Upload_Status__c
                            FROM rC_Connect__Batch_Upload__c Where 
                            Id =: emailId and 
                            Cont1_Optin__c = TRUE and 
                            Cont1_Email__c != NULL];
                            
                if (surgeBUPs.isEmpty()) {
                	isOptedOut = true;
                }
                else {
                	surgeBUP = surgeBUPs[0];
                
	                Id existingEmailId = getEmailId(surgeBUP.Cont1_Email__c);
		        	
	                if (surgeBUP != null && existingEmailId == null) {
	                	emailAddress = surgeBUP.Cont1_Email__c;
		        		maskEmailAddress = maskEmail(emailAddress);
		                isOptedOut = false;  		
		        	}
	                
	                if (existingEmailId != null) {
	                    emailId = existingEmailId;
	                    surgeProcessing = false;
	                }
                }
        	}
        	if (!surgeProcessing) {
	            List<Email__c> objEmailLst = [SELECT Id, Email_address__c, Opt_In__c FROM Email__c WHERE Id =: emailId AND Opt_In__c = true LIMIT 1];
	            if(objEmailLst.size() > 0) {
	                objEmail = objEmailLst.get(0);
	                emailAddress = objEmail.Email_address__c;
	                maskEmailAddress = maskEmail(emailAddress);
	                 
	                String listCode;
	                for(Email_Preference__c emailPref : [SELECT Id, Email_List_Code__c, opt_In__c, Email__c 
	                                                     FROM Email_Preference__c 
	                                                     WHERE Email_List_Code__c != null
	                                                     AND opt_In__c = true
	                                                     AND Email__c =: objEmail.Id]) {
	                    listCode = emailPref.Email_List_Code__c.toLowerCase();                                 
	                    if(allPrefLabelCodeMap != null) {
	                        if(allPrefLabelCodeMap.containsKey(listCode)) {
	                            if(!excludedFromPC.contains(listCode)) {
	                                prefLabelsCodeMap.put(allPrefLabelCodeMap.get(listCode), listCode);
	                            }
	                            emailPrefCodeMap.put(listCode, emailPref);
	                            if(referral.equalsIgnoreCase(listCode)) {
	                                isShowFirstPanel = true;
	                            }
	                        }
	                    }                                   
	                }
	                
	                if(emailPrefCodeMap != null && emailPrefCodeMap.values().size() > 0) {
	                    isShowSecondPanel = true;
	                }
	            } else {
	                isOptedOut = true;
	            }
        	}
        }
    }
    
    public PageReference UpdateMyEmailSub1() {
        List<Email_Preference__c> objEmailPrefLst = new List<Email_Preference__c>();
        String rCode = ApexPages.currentPage().getParameters().get('referralCode');
        if(rCode != null && rCode != '') {
            if(emailPrefCodeMap.containsKey(rCode.toLowerCase())) {
                objEmailPrefLst.add(emailPrefCodeMap.get(rCode.toLowerCase()));
                prefLabelsCodeMap.remove(allPrefLabelCodeMap.get(rCode.toLowerCase()));
            } else if(emailPrefCodeMap.containsKey(rCode.toUpperCase())) {
                objEmailPrefLst.add(emailPrefCodeMap.get(rCode.toUpperCase()));
                prefLabelsCodeMap.remove(allPrefLabelCodeMap.get(rCode.toUpperCase()));
            }
            
            // Special Case for CA
            if(rCode == 'ca') {
                for(String listCode : caListCodes) {
                    if(emailPrefCodeMap.containsKey(listCode)) {
                        objEmailPrefLst.add(emailPrefCodeMap.get(listCode));
                        prefLabelsCodeMap.remove(allPrefLabelCodeMap.get(listCode));
                    }
                }
            }
        }
        for(Email_Preference__c objEmailPref : objEmailPrefLst) {
            objEmailPref.opt_In__c = false;
        }
        if(objEmailPrefLst.size() > 0) {
            try{
                update objEmailPrefLst;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ManageEmailsController','UpdateMyEmailSub1',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
        return Page.ThankYou;
    }
    
    public PageReference UpdateMyEmailSub2() {
        List<Email_Preference__c> emailPrefListToUpdate = new List<Email_Preference__c>();
        isFullOptOt = ApexPages.currentPage().getParameters().get('isFullOptOut');
        List<String> preflabels = new List<String>();
        String prefLabelString = ApexPages.currentPage().getParameters().get('ePrefLabels');
        if(prefLabelString != null) {
            preflabels = ( List<String> )JSON.deserialize(ApexPages.currentPage().getParameters().get('ePrefLabels'),List<string>.class);
        } else if(isFullOptOt == 'true'){
            preflabels.addAll(prefLabelsCodeMap.keySet());
        }
        
        system.debug('****preflabels****'+preflabels);
        for(String label : preflabels) {
            system.debug('****prefLabelsCodeMap****'+prefLabelsCodeMap);
            system.debug('****emailPrefCodeMap****'+emailPrefCodeMap);
            system.debug('****prefLabelsCodeMap.containsKey(label)****'+prefLabelsCodeMap.get(label));
            system.debug('****emailPrefCodeMap.containsKey(prefLabelsCodeMap.get(label))****'+emailPrefCodeMap.get(prefLabelsCodeMap.get(label)));
            if(prefLabelsCodeMap.containsKey(label) && emailPrefCodeMap.containsKey(prefLabelsCodeMap.get(label))) {
                system.debug('********inside if***');
                emailPrefCodeMap.get(prefLabelsCodeMap.get(label)).Opt_In__c = false;
                emailPrefListToUpdate.add(emailPrefCodeMap.get(prefLabelsCodeMap.get(label)));
                prefLabelsCodeMap.remove(label);
            }
        }
        system.debug('****prefLabelsCodeMap****'+prefLabelsCodeMap);
        mapSize = prefLabelsCodeMap.size();
        if(isFullOptOt == 'true') {
            system.debug('******'+objEmail);
            if(objEmail != null && objEmail.Opt_In__c) {
                system.debug('******'+objEmail.Opt_In__c);
                objEmail.Opt_In__c = false;
                isOptedOut = true;
                objEmail.st_unsub_time__c = DateTime.now();
                String unsubUrl = ApexPages.currentPage().getParameters().get('unsub_url');
                objEmail.st_unsub_url__c = unsubUrl;
                try{
                    update objEmail;
                    if(String.isBlank(unsubUrl)) {
                        String mailingId = ApexPages.currentPage().getParameters().get('mailingId');
                        String messageid = ApexPages.currentPage().getParameters().get('messageid');
                        String databaseid = ApexPages.currentPage().getParameters().get('databaseid');
                        String serial = ApexPages.currentPage().getParameters().get('serial');
                        String userid = ApexPages.currentPage().getParameters().get('userid');
                        String emId = emailAddress;
                        performMessageStudioCallout('https://ms.clicks.actions.aclu.org/track?type=unsubscribe&mailingid='+mailingid+'&messageid='+messageid+'&databaseid='+databaseid+'&serial='+serial+'&userid='+userid+'&emailid='+emId+'&&&'+Label.End_URL_For_Message_Studio);
                    }
                } catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('ManageEmailsController','UpdateMyEmailSub2',e.getMessage());
                    log.logException(e);
                    log.saveLogs();
                }
            }
            else if (surgeProcessing && surgeBup.Cont1_Optin__c != false) {
                system.debug('******'+'UPDATE BUP RECORD ' + emailAddress);
                surgeBup.Cont1_Optin__c = false;
                isOptedOut = true;
                try{
                    update surgeBup;
                    
                    updateSurgeDuplicates(surgeBup.Id);
                    
                    String mailingId = ApexPages.currentPage().getParameters().get('mailingId');
                    String messageid = ApexPages.currentPage().getParameters().get('messageid');
                    String databaseid = ApexPages.currentPage().getParameters().get('databaseid');
                    String serial = ApexPages.currentPage().getParameters().get('serial');
                    String userid = ApexPages.currentPage().getParameters().get('userid');
                    String emId = surgeBup.Id;
                    
                    performMessageStudioCallout('https://ms.clicks.actions.aclu.org/track?type=unsubscribe&mailingid='+mailingid+'&messageid='+messageid+'&databaseid='+databaseid+'&serial='+serial+'&userid='+userid+'&emailid='+emId+'&&&'+Label.End_URL_For_Message_Studio);
                
                } catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('ManageEmailsController','UpdateMyEmailSub2',e.getMessage());
                    log.logException(e);
                    log.saveLogs();
                }
            }
        }
        
        if(emailPrefListToUpdate.size() > 0) {
          update emailPrefListToUpdate;
        }
        
        return Page.ThankYou;
    }
    
    @TestVisible
    private static Boolean checkForSurge(Id objId) {
    	String objectId = (String)objId;
    	// String surgeObjPrefix = rc_Connect__Batch_Upload__c.sObjectType.getDescribe().getKeyPrefix();
    	// if(objectId.startsWith(surgeObjPrefix)) { 
    	if(objectId.startsWith('a1M')) { 
        	return true;
    	}
    	return false;
    }
    
    @TestVisible
    public static ID getEmailId(String emailAddress) {
    	List<Email__c> emails = [Select Id, Email_Address__c from Email__c where Email_Address__c = :emailAddress
    	   and Opt_In__c = true
    	   order by Primary__c desc LIMIT 1];
    	if (emails.size() == 1) {
    		return emails[0].Id;
    	}
    	return null;
    }
    
    @TestVisible
    private static String maskEmail(String unmaskedEmail) {
        List<String> mailSplit = String.valueOf(unmaskedEmail).split('@');
        String maskEmailAddress = mailSplit[0].substring(0,1)+'***'+mailSplit[0].substring(mailsplit[0].length()-1,mailsplit[0].length())+'@'+mailSplit[1].substring(0,1)+'***'+mailSplit[1].substring(mailsplit[1].length()-5,mailsplit[1].length());
    	return maskEmailAddress;
    }
    
    @TestVisible
    @future
    private static void updateSurgeDuplicates(Id surgeBupid) {
    	rc_Connect__Batch_Upload__c surgeBup = [Select Id, Cont1_Email__c, Cont1_Optin__c from rc_Connect__Batch_Upload__c where Id = :surgeBupid];
    	Id surgeId = surgeBup.Id;
    	String surgeEmail = surgeBup.Cont1_Email__c;
    	List<rc_Connect__Batch_Upload__c> dupEmailBUPs = [Select Id, Cont1_Email__c from rc_Connect__Batch_Upload__c
    		where rc_Connect__Batch_Upload_Status__c != 'Committed' 
    		and rc_Connect__Batch_Upload_Status__c != 'Processing' 
    		and Cont1_Email__c = :surgeEmail
    		and Id != :surgeId LIMIT 50]; // common-sense limit to avoid some sort of bot update
    	for (rc_Connect__Batch_Upload__c bup : dupEmailBUPs) {
    		bup.Cont1_Optin__c = surgeBup.Cont1_Optin__c;
    	}
    	update dupEmailBUPs;
    }

    @future(callout=true)
    private static void performMessageStudioCallout(String endpoint) {
        HttpRequest req = new HttpRequest(); 
        Http outbound = new Http();
        HTTPResponse res;

        req.setTimeout(calloutDuration);
               
        req.setMethod('POST');
        req.setEndpoint(endpoint);
               
        res = outbound.send(req);
        
    }

    public pageReference redirectThankYouPage(){
        PageReference pg = page.ThankYou;
        pg.setRedirect(true);
        return pg;
    }
   
}
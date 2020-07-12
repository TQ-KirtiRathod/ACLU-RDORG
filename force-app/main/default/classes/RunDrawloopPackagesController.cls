/*
*
*Name  :  RunDrawloopPackagesController
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  April 12, 2017
*Purpose :  Controller class for RunDrawloopPackages Page
            Logic includes but not limited to
            - getters for the VF page
            - Running multiple Drawloop DDPs
            - Population of Custom Salutations fields on Account
            - Email Notificaton to user
            - Calls to Drawloop API's
            - Merge Number update on Opps
*
*/
global class RunDrawloopPackagesController {
    public list<SelectOption> selectedDDPs{get;set;}
    public List<SelectOption> sOptions{get;set;}
    //public List<String> ddpOptions{get;set;}
    public map<String, String> ddpNameToReportName;
    public map<Id, Loop__DDP__c> ddpMap{get;set;}
    public Boolean hasError { get { return ApexPages.hasMessages(); } }
    public Boolean errors{get;set;}
    public Boolean excludeRecords{get;set;}
    public static String prAffiliate;
    public list<SelectOption> salutationFormalTypeList{get;set;}
    public String firstInside{get;set;}
    public String secondInside{get;set;}
    public String firstOutside{get;set;}
    public String secondOutside{get;set;}
    public String thirdInside{get;set;}
    public String thirdOutside{get;set;}
    //public Boolean bypassSalutation{get;set;}
    public String mergeNumber{get;set;}
    public Integer countOfSourceRecords {get; set;}
    public Integer countOfMergeRequests {get; set;}
    public set<Id> opportunityIdSet;
    public static final STring FORMAL_VALUE = 'Account Default Formal Salutation';
    public static final STring INFORMAL_VALUE = 'Account Default Informal Salutation';
    public Loop.loopMessage lm;
    static {
        prAffiliate = [SELECT Primary_Affiliate__c FROM User WHERE Id = :userInfo.getUserId()].Primary_Affiliate__c;
    }
    public RunDrawloopPackagesController() {
        errors = true;
        excludeRecords = false;
        lm = new Loop.loopMessage();
        opportunityIdSet = new set<Id>();
        if(String.isBlank(prAffiliate)) return; //No processing if User's primary Affiliate is null
        firstInside = secondInside = thirdInside = FORMAL_VALUE;
        firstOutside = secondOutside = thirdOutside = FORMAL_VALUE;

        
        ddpMap = new map<Id, Loop__DDP__c>([SELECT Id,Name,RecordType.Name,(SELECT Id FROM Loop__Custom_Integration_Options__r     
                                                    WHERE RecordType.Name = 'Document Queue'),
                                                    (SELECT Id, Name, loop__reportids__c FROM Loop__DDP_Files__r)
                                                    FROM Loop__DDP__c 
                                                    WHERE Primary_Affiliate__c = :prAffiliate]);

        selectedDDPs = new list<SelectOption>();
        List<SelectOption> options = new List<SelectOption>();
        for(Loop__DDP__c ddp : ddpMap.values()) {
            options.add(new SelectOption(ddp.Id,ddp.Name));
        }
        
        sOptions = options;

        //Get salutation preferences
        salutationFormalTypeList = new list<SelectOption>();
        List<Schema.PicklistEntry> picklist_values = rC_Bios__Salutation__c.getSObjectType().getDescribe().fields.getMap().get('rC_Bios__Salutation_Type__c').getDescribe().getPickListValues();
        salutationFormalTypeList.add(new SelectOption(FORMAL_VALUE,FORMAL_VALUE));
        salutationFormalTypeList.add(new SelectOption(INFORMAL_VALUE,INFORMAL_VALUE));

        for(Schema.PicklistEntry pick : picklist_values) {
            salutationFormalTypeList.add(new SelectOption(pick.getValue(),pick.getLabel()));
        }

    }
    public void runDDP() {
        if(String.isBlank(prAffiliate)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Document Package available to process'));
            return;
        }
        if(selectedDDPs.size() == 0) {
            errors = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select at least one Document Package'));
            return;
        }
        
        set<Id> accountIdSet = new set<Id>();
        for(SelectOption ddpId : selectedDDPs) {
            Id packageId = ddpId.getValue();
            map<string, string> variables = new Map<string, string> { 'deploy' => ddpMap.get(packageId).Loop__Custom_Integration_Options__r.get(0).Id };
            map<String, String> recordIdMap = runDocumentPackage(ddpMap.get(packageId));

            for(String idS : recordIdMap.keySet()) {
                if(idS == 'Report Error') {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in ' + ddpMap.get(packageId).Name + '.  '+ recordIdMap.get(idS) ));
                    return;
                }                

                if(idS == 'Error') {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in ' + ddpMap.get(packageId).Name + ' : Second Column of report must be AccountId'));
                    return;
                }
                accountIdSet.add(recordIdMap.get(idS));
                opportunityIdSet.add(idS);
                lm.requests.add(new Loop.loopMessage.loopMessageRequest((Id)idS, packageId, variables));
            }
        }
        //if(!bypassSalutation) {
            set<String> prefList = new set<String>{firstInside, firstOutside, secondInside, secondOutside, thirdInside, thirdOutside};
            
            map<String, rC_Bios__Salutation__c> salutationRecordsMap = new map<String, rC_Bios__Salutation__c>();
            if((firstInside != FORMAL_VALUE && firstInside != INFORMAL_VALUE) || (firstOutside != FORMAL_VALUE && firstOutside != INFORMAL_VALUE)) {
                for(rC_Bios__Salutation__c sal: [SELECT Id, rC_Bios__Salutation_Type__c, Name,rC_Bios__Inside_Salutation__c, 
                                                    rC_Bios__Salutation_Line_1__c, rC_Bios__Salutation_Line_2__c,rC_Bios__Salutation_Line_3__c,
                                                    rC_Bios__Account__c
                                                    FROM rC_Bios__Salutation__c 
                                                    WHERE rC_Bios__Salutation_Type__c IN :prefList
                                                    AND rC_Bios__Account__c IN :accountIdSet]) {
                    if(!salutationRecordsMap.containsKey(sal.rC_Bios__Account__c)) {
                        salutationRecordsMap.put(sal.rC_Bios__Account__c + '~' + sal.rC_Bios__Salutation_Type__c, sal);
                    }
                }
                
            }
            prefList = null;
            list<Account> accountsToUpdate = [SELECT Id, Name, Custom_Inside_Salutation__c, Custom_Outside_Salutation_Line_1__c,
                                                Custom_Outside_Salutation_Line_2__c, Custom_Outside_Salutation_Line_3__c,
                                                Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c,
                                                Informal_Inside__c, Informal_Outside_1__c, Informal_Outside_2__c, Informal_Outside_3__c
                                                FROM Account WHERE Id IN :accountIdSet];
            for(Account acc : accountsToUpdate) {
                //For Inside Salutations
                if(firstInside == FORMAL_VALUE) {
                    acc.Custom_Inside_Salutation__c = acc.Formal_Inside__c;
                } else if(firstInside == INFORMAL_VALUE) {
                    acc.Custom_Inside_Salutation__c = acc.Informal_Inside__c;
                } else if(salutationRecordsMap.containsKey(acc.Id + '~' + firstInside)) {
                    acc.Custom_Inside_Salutation__c = salutationRecordsMap.get(acc.Id + '~' + firstInside).rC_Bios__Inside_Salutation__c;
                } else if(secondInside == FORMAL_VALUE) {
                    acc.Custom_Inside_Salutation__c = acc.Formal_Inside__c;
                } else if(secondInside == INFORMAL_VALUE) {
                    acc.Custom_Inside_Salutation__c = acc.Informal_Inside__c;
                } else if(salutationRecordsMap.containsKey(acc.Id + '~' + secondInside)) {
                    acc.Custom_Inside_Salutation__c = salutationRecordsMap.get(acc.Id + '~' + secondInside).rC_Bios__Inside_Salutation__c;
                } else if(thirdInside == FORMAL_VALUE) {
                    acc.Custom_Inside_Salutation__c = acc.Formal_Inside__c;
                } else if(thirdInside == INFORMAL_VALUE) {
                    acc.Custom_Inside_Salutation__c = acc.Informal_Inside__c;
                } else if(salutationRecordsMap.containsKey(acc.Id + '~' + thirdInside)) {
                    acc.Custom_Inside_Salutation__c = salutationRecordsMap.get(acc.Id + '~' + thirdInside).rC_Bios__Inside_Salutation__c;
                } else {
                    acc.Custom_Inside_Salutation__c = '';
                }
                
                //For outside salutations
                if(firstOutside == FORMAL_VALUE) {
                    acc.Custom_Outside_Salutation_Line_1__c = acc.Formal_Outside_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = acc.Formal_Outside_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = acc.Formal_Outside_3__c;
                } else if(firstOutside == INFORMAL_VALUE) {
                    acc.Custom_Outside_Salutation_Line_1__c = acc.Informal_Outside_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = acc.Informal_Outside_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = acc.Informal_Outside_3__c;
                } else if(salutationRecordsMap.containsKey(acc.Id + '~' + firstOutside)) {
                    acc.Custom_Outside_Salutation_Line_1__c = salutationRecordsMap.get(acc.Id + '~' + firstOutside).rC_Bios__Salutation_Line_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = salutationRecordsMap.get(acc.Id + '~' + firstOutside).rC_Bios__Salutation_Line_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = salutationRecordsMap.get(acc.Id + '~' + firstOutside).rC_Bios__Salutation_Line_3__c;
                } else if(secondOutside == FORMAL_VALUE) {
                    acc.Custom_Outside_Salutation_Line_1__c = acc.Formal_Outside_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = acc.Formal_Outside_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = acc.Formal_Outside_3__c;
                } else if(secondOutside == INFORMAL_VALUE) {
                    acc.Custom_Outside_Salutation_Line_1__c = acc.Informal_Outside_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = acc.Informal_Outside_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = acc.Informal_Outside_3__c;
                } else if(salutationRecordsMap.containsKey(acc.Id + '~' + secondOutside)) {
                    acc.Custom_Outside_Salutation_Line_1__c = salutationRecordsMap.get(acc.Id + '~' + secondOutside).rC_Bios__Salutation_Line_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = salutationRecordsMap.get(acc.Id + '~' + secondOutside).rC_Bios__Salutation_Line_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = salutationRecordsMap.get(acc.Id + '~' + secondOutside).rC_Bios__Salutation_Line_3__c;
                } else if(thirdOutside == FORMAL_VALUE) {
                    acc.Custom_Outside_Salutation_Line_1__c = acc.Formal_Outside_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = acc.Formal_Outside_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = acc.Formal_Outside_3__c;
                } else if(thirdOutside == INFORMAL_VALUE) {
                    acc.Custom_Outside_Salutation_Line_1__c = acc.Informal_Outside_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = acc.Informal_Outside_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = acc.Informal_Outside_3__c;
                } else if(salutationRecordsMap.containsKey(acc.Id + '~' + thirdOutside)) {
                    acc.Custom_Outside_Salutation_Line_1__c = salutationRecordsMap.get(acc.Id + '~' + thirdOutside).rC_Bios__Salutation_Line_1__c;
                    acc.Custom_Outside_Salutation_Line_2__c = salutationRecordsMap.get(acc.Id + '~' + thirdOutside).rC_Bios__Salutation_Line_2__c;
                    acc.Custom_Outside_Salutation_Line_3__c = salutationRecordsMap.get(acc.Id + '~' + thirdOutside).rC_Bios__Salutation_Line_3__c;
                } else {
                    acc.Custom_Outside_Salutation_Line_1__c = '';
                    acc.Custom_Outside_Salutation_Line_2__c = '';
                    acc.Custom_Outside_Salutation_Line_3__c = '';
                }
            }
            if(accountsToUpdate.size() > 0) {
                update accountsToUpdate;
            }
        //}
        errors = false;
        countOfMergeRequests = lm.requests.size();
        countOfSourceRecords = opportunityIdSet.size();
    }
    
    public PageReference sendRequests() {
        if(!errors) {
            if(lm.requests.size() > 0) {
                //Generate Merge Job Number
                Integer len = 5;
                Blob blobKey = crypto.generateAesKey(128);
                String key = EncodingUtil.convertToHex(blobKey);
                mergeNumber = '' + system.today().year() + system.today().month() + system.today().day() + '-' + key.substring(0,len);
                
                lm.sendAllRequests();
                //Send email to user
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(userInfo.getUserId());
                //message.optOutPolicy = 'FILTER';
                message.subject = 'Merge Job Number for Drawloop Process';
                message.plainTextBody = 'Your Merge Job Number is : ' + mergeNumber + 
                    '\nYou are creating ' + countOfMergeRequests + ' documents from ' + countOfSourceRecords + ' source records.';
                message.setSaveAsActivity(false);
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                BatchUpdateMergeNumberOnOpportunity nextBatch = new BatchUpdateMergeNumberOnOpportunity(mergeNumber, opportunityIdSet, excludeRecords, prAffiliate);
                Database.executeBatch(nextBatch, 200); 
            }
            
        }
        return null;
    }


    public static map<String,String> runDocumentPackage(Loop__DDP__c ddp) {
        try{
            map<String, String> recordIdMap = new map<String, String>();
            // Run the report

            Integer x = ddp.Loop__DDP_Files__r.get(0).loop__reportids__c.indexOf('\"id\":"');
            
            Reports.ReportResults results;
            if(!Test.isRunningTest()) {
                results = Reports.ReportManager.runReport(ddp.Loop__DDP_Files__r.get(0).loop__reportids__c.subString(x+6, x+24), true);
            } else {
                results = Reports.ReportManager.runReport(ddp.Loop__DDP_Files__r.get(0).loop__reportids__c, true);
            }
            Reports.ReportMetadata rm = results.getReportMetadata();
            if(rm.getDetailColumns().size() <=2 || (rm.getDetailColumns().get(1) != 'ACCOUNT_ID' && rm.getDetailColumns().get(1) != 'Account.Id')) {
                recordIdMap.put('Error', 'Error');
                return recordIdMap;
            }
            list<String> reportColumns = rm.getDetailColumns();

            String factMapKey = 'T!T';
            Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            list<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            for(Reports.ReportDetailRow det : detailRows) {
                recordIdMap.put((String)det.getDataCells().get(0).getValue(), (String)det.getDataCells().get(1).getValue()); // Map of first column in report (Giving Id) and second column (Account Id)
            }
            
            return recordIdMap;
        } catch (Exception e) {
            map<String, String> recordIdMap = new map<String, String>();
            String msg= 'There was an issue running the report, the report may have timed out.';
            recordIdMap.put('Report Error', msg);
            return recordIdMap;
        }
    }
    

    @future
    public static void updateMergeNumberOnOpps(String mergeJobNumber, set<Id> oppIdSet, Boolean excludeRecords, String primaryAffiliate) {
        //updates merge job number
        list<Opportunity> opportunitiesToUpdate = [SELECT Id, Merge_Job_Number__c FROM Opportunity
                                                        WHERE Id IN :oppIdSet];
       for(Opportunity opp : opportunitiesToUpdate) {
            opp.Merge_Job_Number__c = mergeJobNumber;
        }

        //updates excluded records
        if(excludeRecords) {
            //updateOpportunities(excludeRecords, prAffiliate, oppIdSet);
            primaryAffiliate = primaryAffiliate.subString(0,2) + ' %';
            list<Opportunity> oppListToUpdate = [SELECT Id, Acknowledgment_Status__c FROM Opportunity 
                                                    WHERE Acknowledgment_Code__c LIKE :primaryAffiliate
                                                    AND Acknowledgment_Status__c = 'N - Not Acknowledged'
                                                    AND rC_Giving__Acknowledged_Date__c = null
                                                    AND StageName = 'Completed'
                                                    AND id Not In :oppIdSet];
            if(oppListToUpdate.size() > 0){
               for(Opportunity opp1 : oppListToUpdate) {
                   opp1.Acknowledgment_Status__c = 'B - Manually Bypassed From Acknowledgements';
                   opportunitiesToUpdate.add(opp1);
               } 
            }
        } 

        if(opportunitiesToUpdate.size() > 0) {
            try{
                update opportunitiesToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RunDrawloopPackagesController','updateMergeNumberOnOpps',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }

    }
    
}
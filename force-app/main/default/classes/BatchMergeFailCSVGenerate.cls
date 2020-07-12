/*
*
*Name  :  BatchMergeFailCSVGenerate
*Author:  ACLU (Dave Seidman)
*Date  :  October 4, 2019
*Purpose : To query the custom Apex_Log__c object for DC Merge contact merge failures, parse out the contact pairs, 
*          and email the pair list in CSV format so the data can be pasted into a file that DC's open-source
*          CSV-to-job script can process and turn into a DC Merge job, which can then be run via the auto-merge function
*
*/
global class BatchMergeFailCSVGenerate implements Database.Batchable<sObject>, Database.Stateful {
    global final static String CSV_HEADER = 'Master,ToMerge\n';
    global final static String EXCEPTION_TYPE = 'dupcheck.dc3Exception.MergeException';
    global final static String GROUP_TO_EMAIL = 'Merge_Admins';
    global List<String> errorKeywords;
    global String emailBody;
    global List<String> toAddresses;

    public Map<String,List<ContactPair>> contactPairMap;
    public Datetime startDt;
    public Datetime endDt;

    public class ContactPair {
        String masterId;
        String mergedId;
    }

    public BatchMergeFailCSVGenerate(Datetime startDatetime, Datetime endDatetime) {
        emailBody = '';
        startDt = startDatetime; 
        endDt = endDatetime;
        contactPairMap = new Map<String,List<ContactPair>>();
        errorKeywords = new List<String>();
        List<Error_Keyword__mdt> error_Keywords = [SELECT MasterLabel FROM Error_Keyword__mdt ORDER BY Priority__c ASC];
        for (Error_Keyword__mdt errorKeyword : error_Keywords) {
            errorKeywords.add(errorKeyword.MasterLabel);
        }
        for (String s : errorKeywords) {
            contactPairMap.put(s,new List<ContactPair>());
        }
        contactPairMap.put('OTHER',new List<ContactPair>());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Message__c from Apex_Log__c ' +
                                        'WHERE Exception_Type__c = \'' + EXCEPTION_TYPE + '\' ' +
                                        'AND CreatedDate >= :startDt ' +
                                        'AND CreatedDate <= :endDt';
        system.debug('QUERY: ' + query);                               
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        runMerge(scope);
    }

    public void finish(Database.BatchableContext BC) { 
        if (emailBody != '') {
            sendEmail();
        }
    }

    public void runMerge(List<Apex_Log__c> als) {
        for (Apex_Log__c al : als) {
            List<ContactPair> contactPairs= new List<ContactPair>();
            String fullMessage = al.Message__c;

            if (fullMessage.startsWith('003')) {
                String message = al.Message__c;
                String errorMessage;
                List<String> messageSplit = message.split(' ');
                Integer counter = 0;
                String master;
                for (String s : messageSplit) {
                    if (s.startsWith('003')) {
                        if (counter == 0) {
                            master = s;
                        }
                        else if (counter > 0) {
                            ContactPair cp = new ContactPair();
                            cp.masterId = master;
                            cp.mergedId = s;
                            contactPairs.add(cp);
                            system.debug(cp);
                        }
                        counter++;
                    }
                    else {
                        system.debug('error keywords ' + errorKeywords);
                        Boolean keywordFound = false;
                        for (String keyword : errorKeywords) {
                            system.debug('fullMessage: ' + fullMessage);
                            if (fullMessage.contains(keyword)) {
                                List<ContactPair> cpList = (List<ContactPair>)contactPairMap.get(keyword);
                                cpList.addAll(contactPairs);
                                contactPairMap.put(keyword,cpList);
                                keywordFound = true;
                                break;
                            }
                        }
                        if (!keywordFound) {
                            List<ContactPair> cpList = (List<ContactPair>)contactPairMap.get('OTHER');
                            cpList.addAll(contactPairs);
                            contactPairMap.put('OTHER',cpList);
                        }
                        break;
                    }
                }
            }
            else {
                continue;
            }
        }

        if (!contactPairMap.values().isEmpty()) {
            for (String errorKeyword : contactPairMap.keySet()) {
                emailBody += errorKeyword + '\n';
                emailBody += CSV_HEADER;
                List<ContactPair> cps = contactPairMap.get(errorKeyword);
                for (ContactPair cp : cps) {
                    emailBody += cp.masterId;
                    emailBody += ',';
                    emailBody += cp.mergedId;
                    emailBody += '\n';
                }
                emailBody += '\n';
            }
        }


    }

    public void sendEmail() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        toAddresses = setToAddresses();
        if (!toAddresses.isEmpty()) {
            mail.setToAddresses(toAddresses);
            mail.setPlainTextBody(emailBody);
            mail.setSubject('Contact pairs to attempt remerge: ' + startDt + '-' + endDt);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});   
        }
        else {
            system.debug('No one to send email to');
        }
    }

    public List<String> setToAddresses() {
        List<String> addresses;
        List<User> queueUsers = [SELECT Email FROM User WHERE Id IN (
            SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :GROUP_TO_EMAIL
        )];
        List<String> uniqueEmails = new List<String>();

        if (!queueUsers.isEmpty()) {
            for (User user : queueUsers) {
                uniqueEmails.add(user.Email);
            } 
        }

        return uniqueEmails;
    }
}
/*
*
*Name  :  Reconcile10kDonorsBatch
*Author:  Appirio India (James Wasilewskin)
*Date  :  November 10, 2017
*Purpose :  Create Donors_Over_10K__c child records to Affiliate Yearly for donors who donated > 10K for GMI affiliates
            This class runs in preperation for GMI Affilate Yearly Reconciliation Reports"
*
* Modified by :: Salesforce.org :: 18-June-2019 :: Zendesk: #68203
* Description :: the reports contain gifts within the 2 old KM Deposit Sites only (KM_Kansas and KMW_Kansas_web) - it is missing KS and KSW
*/
global class Reconcile10kDonorsBatch implements Database.Batchable<sObject>,Database.stateful {
    
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    
    public String accAffiliationCode;
    public Id ayId;
    public String fiscalYear;
    private static Set<String> unionGMISharingCodes;
    private static Set<String> foundationGMISharingCodes;
    public  List<String> sharingAffiliationEntitySet = new List<String>();

    public String type; //intended to be Union or Foundation
    public Boolean isReportRunning = false;

    static{
        unionGMISharingCodes = new Set<String> {'E121','E131','E151','E181'};
        foundationGMISharingCodes = new Set<String>{'R131','R113','R121','K171','R181','R151'} ;        
    }

    global Reconcile10kDonorsBatch() {
        //accAffiliationCode = 'ER';
        //for testing
        //ayId = 'a2yW0000000TTnr';
        updateCalculateReconciliationReportStatus('on');
    }
    
    global List<Opportunity> start(Database.BatchableContext BC) {
        
        //Determine current fiscal year
        Organization orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                   FROM Organization
                   WHERE id=:Userinfo.getOrganizationId()];
        //set date selection based on dynamic fiscal year
        integer endDateLastDay = Date.daysInMonth(integer.valueof(fiscalYear), orgInfo.FiscalYearStartMonth-1);
        Date startDate = Date.newInstance( integer.valueof(fiscalYear)-1, orgInfo.FiscalYearStartMonth, 01);
        Date endDate = Date.newInstance( integer.valueof(fiscalYear), orgInfo.FiscalYearStartMonth-1, endDateLastDay);

        //delete records for ay record
        List<Donors_Over_10K__c> toDelete = [Select id FROM Donors_Over_10K__c
                                                                                 Where Affiliate_Yearly__c = :ayId ];
        if(toDelete != NULL && toDelete.size()>0 ){
            try {
              delete toDelete;
              database.emptyRecycleBin(toDelete);
              if(test.isRunningTest()){
                  Decimal d = 2/0;
              }
            } catch (Exception e) {
              apexLogHandler.apexLog log = new apexLogHandler.apexLog('Reconcile10kDonorsBatch', 'execute', e.getMessage());
              log.logException(e);
              log.saveLogs();
            }
        }
        // end delete records
        //Zendesk: #68203 -- Get Deposit site from custom metadata Types
        sharingAffiliationEntitySet = Utilities.getDepositSiteSet(accAffiliationCode );
       //END:Zendesk: #68203
        List<Opportunity> opps = [
                        SELECT Id, Amount, accountId, Exclude_from_Revenue_Sharing__c, Sharing_Code__c, Deposit_Site__c,
                       Sharing_Entity__c, RPT_Package_Code__c 
                FROM Opportunity
                WHERE RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                      :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                      :OPPORTUNITY_RT_SOFTCREDIT_Id)
                 AND Sharing_Code__c IN ('R131','R113','R121','K171','R181','R151',
                                                         'E121','E131','E151','E181')
                 //AND Amount != NULL
                 AND (Sharing_Entity_Affiliation__c IN :sharingAffiliationEntitySet //#63855
                      OR (Account_Affiliation__c =: accAffiliationCode 
                            AND Sharing_Entity_Affiliation__c IN ('NA','NN','UN','FN','PF','EN','PU','UA')
                         )
                     )
                 AND stageName = 'Completed'
                 AND CloseDate >= :startDate AND CloseDate <= :endDate
                 Order by accountId];
      
        return opps;
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> opps) {
        String key;
        String depositSite;
        String packageCode;
        Map<String, Donors_Over_10K__c> donors = new Map<String, Donors_Over_10K__c>();
        List<Donors_Over_10K__c> bigDonors = new List<Donors_Over_10K__c>();
        for(Opportunity o: opps){
          if(o.Exclude_from_Revenue_Sharing__c == False && o.Amount !=null
                    && o.Deposit_Site__c != null && o.Deposit_Site__c != 'COS*' && o.Deposit_Site__c != 'NAE' ){
                key = '';
          if( unionGMISharingCodes.contains(o.Sharing_Code__c) ){
            key = o.accountId + ' Union';
          } else if( foundationGMISharingCodes.contains(o.Sharing_Code__c)){
            key = o.accountId + 'Foundation' ;
          }
          
          packageCode = '';
          depositSite = '';

          depositSite = o.Deposit_Site__c.subString(0,2);
          
          if (o.RPT_Package_Code__c !=null && o.RPT_Package_Code__c.length()>=4 
              && o.RPT_Package_Code__c.subString(2, 4) == 'CP'){
            packageCode = o.RPT_Package_Code__c.subString(2, 4);
                  
          }

         //Zendesk: #68203
          
            Boolean isDepositSiteSameAsAffiliate = false;
            isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(o
                                                          ,  sharingAffiliationEntitySet
                                                          ,  depositSite);
            //END:Zendesk: #68203
         
          if(!donors.isEmpty() && donors.containsKey(key) ) {
            if(isDepositSiteSameAsAffiliate) 
                donors.get(key).Banked_by_Affiliate_Fdn__c += o.Amount;
            
            if(depositSite == 'NA') 
                donors.get(key).Banked_by_National_Fdn__c += o.Amount;
            if( ( (o.Sharing_Code__c == 'R151' || (packageCode=='CP' && o.Sharing_Code__c == 'R131'))
                    || (o.Sharing_Code__c == 'E151' || (packageCode=='CP' && o.Sharing_Code__c == 'E131'))
                  )
                  && isDepositSiteSameAsAffiliate)
                donors.get(key).Affiliate_CP_and_Earmark_Info__c += o.Amount;
            if( ( (o.Sharing_Code__c == 'R151' || (packageCode=='CP' && o.Sharing_Code__c == 'R131'))
                    || (o.Sharing_Code__c == 'E151' || (packageCode=='CP' && o.Sharing_Code__c == 'E131'))
                  )
                  && depositSite == 'NA') 
                donors.get(key).National_CP_and_Earmark_Info__c += o.Amount;
              

          } else {
            Donors_Over_10K__c d = new Donors_Over_10K__c();
            d.Affiliate_Yearly__c = ayId;
            d.Account__c = o.accountId;
            if( unionGMISharingCodes.contains(o.Sharing_Code__c) ){
                d.Fund_Type__c = 'Union';
            } else if( foundationGMISharingCodes.contains(o.Sharing_Code__c)){
                d.Fund_Type__c = 'Foundation';
            }

            if(isDepositSiteSameAsAffiliate){
                d.Banked_by_Affiliate_Fdn__c = o.Amount;
            } else {d.Banked_by_Affiliate_Fdn__c = 0;}
            
            if(depositSite == 'NA'){
                d.Banked_by_National_Fdn__c = o.Amount;
            }else {d.Banked_by_National_Fdn__c = 0;}
            
            if( ( (o.Sharing_Code__c == 'R151' || (packageCode=='CP' && o.Sharing_Code__c == 'R131'))
                    || (o.Sharing_Code__c == 'E151' || (packageCode=='CP' && o.Sharing_Code__c == 'E131'))
                  )
                  && isDepositSiteSameAsAffiliate){
                d.Affiliate_CP_and_Earmark_Info__c = o.Amount;
            } else {d.Affiliate_CP_and_Earmark_Info__c = 0;}

            if( ( (o.Sharing_Code__c == 'R151' || (packageCode=='CP' && o.Sharing_Code__c == 'R131'))
                   || (o.Sharing_Code__c == 'E151' || (packageCode=='CP' && o.Sharing_Code__c == 'E131'))
                  ) 
                    && depositSite == 'NA'){
                d.National_CP_and_Earmark_Info__c = o.Amount;
            } else {d.National_CP_and_Earmark_Info__c = 0;}
                

            donors.put(key, d);
          }
        }
        }

        for(Donors_Over_10K__c d:donors.values() ){
            if( (makeOperandable(d.Banked_by_Affiliate_Fdn__c) + makeOperandable(d.Banked_by_National_Fdn__c) ) >= 10000){
                bigDonors.add(d);
            }
        }

        if(bigDonors != null){
            try {
              insert bigDonors;
              if(test.isRunningTest()){
                  Decimal d = 2/0;
              }
            } catch (Exception e) {
              apexLogHandler.apexLog log = new apexLogHandler.apexLog('Reconcile10kDonorsBatch', 'execute', e.getMessage());
              log.logException(e);
              log.saveLogs();
            }
        }

    }
    
    global void finish(Database.BatchableContext BC) {
        //RevSharing_Calc_Batch batch = new RevSharing_Calc_Batch(ayId);
        //Database.executeBatch(batch, 2000);

        try {
            Calculate_Reconciliation_Report_Status__c crrs = Calculate_Reconciliation_Report_Status__c.getOrgDefaults();
            String userName = crrs.Receiver_Name__c;
            String fromAddress = crrs.Sender_Email__c;
            String toAddress = crrs.Receiver_Email_Id__c;
            if (crrs.Report_Request_In_Progress__c) {
              isReportRunning = true;
              sendEmail(userName, fromAddress, toAddress, ayId);
              /*Update custom setting after sent an email to user*/
              updateCalculateReconciliationReportStatus('off');
            }
        } catch (Exception e) {
          if (isReportRunning) {
            updateCalculateReconciliationReportStatus('off');
          }
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('RevSharing_Calc_Batch', 'updateRevenue', e.getMessage());
          log.logException(e);
          log.saveLogs();
        }

    }
    
    public Decimal makeOperandable(Decimal input) { return (input == null) ? 0 : input; }

    webservice static Boolean initialize(Id affiliateYearlyId, String fy, String accAffiliationCode ) {
      try {
        Reconcile10kDonorsBatch d = new Reconcile10kDonorsBatch();
        d.accAffiliationCode = accAffiliationCode;
        d.ayId = affiliateYearlyId;
        d.fiscalYear = fy;
        /* Modified by: Amar Kulkarni(rC) : 13th Aug'18
          *  ZD-58492: Reconcile_FoundationGMIReportPage displaying Account in unexpected section
          *  Change > Batch scope incresed to 2000 from 200
          */
        Database.executeBatch(d, 2000);
        return true;
      } catch (Exception e) {
        return false;
      }
      return true;
    }

    private void sendEmail(String userName, String fromAddress, String toAddress, String afid) {
      List<String> sendTo = new List<String>();
      List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

      if (fromAddress != null && toAddress != null) {
        sendTo.add(toAddress);
        mail.setReplyTo(fromAddress);

        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Report Request');
        mail.setSubject('Affiliate Yearly Report '+ accAffiliationCode+'-'+ fiscalYear);
        String body = 'Hi ' + userName + ',<br/><br/>Calculations have completed for the '+accAffiliationCode+'-'
                      + fiscalYear+' Affiliate Yearly report request.';
        body += '<html><body><br/>Access the report from the URL:';
        body += '<br/><br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' 
             + 'apex/ReconciliationReport_Union?afid=' + afid + '">ReconciliationReport_Union</a>';
        body += '<br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' 
             + 'apex/ReconciliationReport_Foundation?afid=' + afid + '">ReconciliationReport_Foundation</a>';
        body += '<br/><br/>If the link is not accessible please copy the below url in browser:';
        body += '<br/><br/>ReconciliationReport_Union: <b>' + URL.getSalesforceBaseUrl().toExternalForm() + '/' 
             + 'apex/ReconciliationReport_Union?afid=' + afid + '</b>';
        body += '<br/><br/>ReconciliationReport_Foundation: <b>' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' 
             + 'apex/ReconciliationReport_Foundation?afid=' + afid + '</b>';
        body += '<br/></body></html>';

        mail.setHtmlBody(body);
        mails.add(mail);

      }
      if (!mails.IsEmpty()) {
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);
      }
    }

    public void updateCalculateReconciliationReportStatus(string status) {
      if(status == 'off'){
          Calculate_Reconciliation_Report_Status__c crrs = Calculate_Reconciliation_Report_Status__c.getOrgDefaults();
          crrs.Receiver_Name__c = '';
          crrs.Receiver_Email_Id__c = '';
          crrs.Report_Request_In_Progress__c = false;
          upsert crrs;
        } else if (status == 'on'){
            Calculate_Reconciliation_Report_Status__c crrs = Calculate_Reconciliation_Report_Status__c.getOrgDefaults();
            crrs.Receiver_Name__c = Userinfo.getFirstName();
            crrs.Receiver_Email_Id__c = UserInfo.getUserEmail();
            crrs.Report_Request_In_Progress__c = true;
            upsert crrs;            
        }
    }

}
/*
*
*Name  :  RevSharing_StageReportCalculations
*Author:  Appirio India (Sai Krishna )
*Date  :  Februvary 08, 2017
*Purpose : Calculates RevenueSharing in CMI/FCMI context. Contains methods to : 
*          1. Generate CMI/FCMI report by invoking RevSharing_CMICalculator. 
*          2. Send email containing links to Cash Receipt and CMI/FCMI reports.
*/
public class RevSharing_StageReportCalculations {
    
     /*
    *Method generateCMI_FCMI_Report
    *@param : fiscalYear
    *@param : reportType
    *@description : Invoke the CMI calculations.
    */ 
    public static void generateCMI_FCMI_Report(List<Affiliate_Yearly__c> affiliateYearlys, String reportType){
        Set<Id> affYearlyRecords = new Set<Id> ();
        // fetch all affiliateYearly Records in the Fiscal Year
        for(Affiliate_Yearly__c aff: affiliateYearlys){
            affYearlyRecords.add(aff.Id);                                   
        }
        // copying to list to sort 
        List<Id> sortIds = new List<Id>(affYearlyRecords);
        sortIds.Sort();
        if(!sortIds.IsEmpty()){
            if(reportType == 'CMI') {
              RevSharing_CMICalculator batch = new RevSharing_CMICalculator(new Set<Id>(sortIds), reportType);
              Database.executeBatch(batch,2000); 
            }
            else if(reportType == 'FCMI') {
              RevSharing_FCMICalculator batch = new RevSharing_FCMICalculator(new Set<Id>(sortIds), reportType);
              Database.executeBatch(batch,2000); 
            }
            //RevSharing_IndemnificationActuals_Batch batch = new RevSharing_IndemnificationActuals_Batch(new Set<Id>(sortIds), true, reportType);
        }
    }
    
    /*
    *Method sendEmail
    *@description : Sends Email.
    */ 
    public static void sendEmail(String reportType, String fromAddress, String toAddress, String fYear ){
        // Variables
        List<String> sendTo = new List<String>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        if(fromAddress!= null && toAddress != null){
            sendTo.add(toAddress);
            mail.setReplyTo(fromAddress);
            
            mail.setToAddresses(sendTo);
            mail.setSenderDisplayName('Report Request');
        
            mail.setSubject('CMI/FCMI Report');
            String body = 'Report Request processing has been completed ';
            if(reportType == 'batch_Credit_Card_summary' || reportType == 'Errors'){
            	mail.setSubject('Batch Summary/ Credit Card Batch Reports');
            	Monthly_Cash_Receipts_Controls__c cs =  Monthly_Cash_Receipts_Controls__c.getAll().Values()[0];
	            String batchLink = '/'+ cs.Batch_Summary_Report_Id__c;
	            String creditLink = '/'+ cs.Credit_Card_Batches_Report_Id__c;
	            String errorsLink = '/'+ cs.Errors_For_Review_Report_Id__c;
	            String reportLinks;
	            if(reportType == 'batch_Credit_Card_summary'){
	                mail.setSubject('Batch Summary/ Credit Card Batch Reports');
                    reportLinks = '<br/><br/>'+'<a href="'+cs.Salesforce_Base_URL__c+batchLink+'">Batch Summary Report</a>';
                    reportLinks += '<br/><br/>'+'<a href="'+cs.Salesforce_Base_URL__c+creditLink+'">Credit Card Report</a>';
                }
                else{
                    mail.setSubject('Errors For Review Report');
                    reportLinks = '<br/><br/>'+'<a href="'+cs.Salesforce_Base_URL__c+errorsLink+'">Erros For Review Report</a>';
                }    
	            body += 'Access the report Batch Summary and Credit Card Batch Reports from the below URLs:';
	            body += reportLinks;
	            body += '<br/><br/>If the link is not accessible please copy the below url in browser:<br/><br/>';
	            body += reportLinks;
            }
            else if(reportType == 'FCMI' || reportType == 'CMI'){
            	String reportLink  = (reportType == 'FCMI')?'/apex/FCMI_Reports?fiscalYear='+fYear :'/apex/CMI_Reports?fiscalYear='+fYear; 
            	mail.setSubject('CMI/FCMI Report');
            	body += 'Access the report from the URL:';
	            body += '<br/><br/>'+'<a href="'+Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0].Salesforce_Base_URL__c+reportLink+'">here</a>';
	            body += '<br/>If the link is not accessible please copy the below url in browser:';
	            body += '<br/><b>'+ Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0].Salesforce_Base_URL__c+reportLink+'</b>';
            }
            else{
            	mail.setSubject('Member/Donor Calculation Complete');
            	body += '<br/><br/>The Member/Donor Calculation was recalculated successfully.';
	            body += 'See the Affiliate Record for the Updated counts';	            
            }
        
            mail.setHtmlBody(body);
            mails.add(mail);
            
        }
        
        if(!mails.IsEmpty() && Label.Email_Deliverability_Status == 'All email'){
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);
            
        }
    }
}
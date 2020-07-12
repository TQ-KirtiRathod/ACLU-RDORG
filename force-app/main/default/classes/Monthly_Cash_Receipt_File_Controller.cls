/*
*
*Name  :  Monthly_Cash_Receipt_File_Controller
*Author:  Appirio India (Sai Krishna )
*Date  :  February 17, 2017
*Purpose : Controller for VF page Monthly_Cash_Receipt_File /apex/Monthly_Cash_Receipt_File
*
*/

public class Monthly_Cash_Receipt_File_Controller {
  public Boolean isShowError { get; set; }

  public String selectedReportType { get; set; }

  public Batch_Log__c batchLog { get; set;}

  public Boolean isConfirm {get; set;}

  /*
  *Method RevenueSharingAdminController
  *@description : Class Controller.
  */
  public Monthly_Cash_Receipt_File_Controller () {
    isShowError = false;
    batchLog = new Batch_Log__c ();
    isConfirm = false;

  }

  /*
  *Method save
  *@description : save the values and triggers the CMI calculations.
  */
  public pageReference save() {
    if (validation()) {
      isShowError = false;

      if (selectedReportType == 'batch_Credit_Card_summary' || selectedReportType == 'Errors') {

        Monthly_Cash_Receipts_Controls__c mCRC = Monthly_Cash_Receipts_Controls__c.getAll().Values()[0];
        try {
          update new Monthly_Cash_Receipts_Controls__c(Id = mCRC.Id, 
                                                       Report_Request_Owner_Email__c = UserInfo.getUserEmail(),
                                                       Salesforce_Base_URL__c = URL.getSalesforceBaseUrl().toExternalForm()
                                                      );
        } catch (Exception e) {
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('Monthly_Cash_Receipt_File_Controller', 
                                                                  'save', e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
        Database.executeBatch(new BatchLogSummariesDeleteBatch(batchLog.Bank_Date__c, batchLog.Batch_Date__c, selectedReportType), 2000);
        isConfirm = true;
      } else {
        return new PageReference('/apex/Cash_Receipt_Reports?reportType=' + selectedReportType + '&startDate=' 
                                 + batchLog.Bank_Date__c + '&endDate=' + batchLog.Batch_Date__c);
      }
    }
    return null;
  }

  /*
  *Method validation
  *@description : Validates the Input fields
  */
  public Boolean validation() {
    if (batchLog.Bank_Date__c != null && batchLog.Batch_Date__c != null) {
      return true;
    } else {
      isShowError = true;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Start Date and End Date are required');
      ApexPages.addMessage(myMsg);
      return false;
    }
  }

}
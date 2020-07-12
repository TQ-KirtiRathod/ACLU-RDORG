/*
*
*Name  :  ReconciliationReportController
*Author:  Appirio (James Wasilewski)
*Date  :  May 23, 2017
*Purpose : Controller class for ReconciliationReport_Union & ReconciliationReport_Foundation Page determines which report will be 
*          redirected to based on affiliate yearly record
*
*/
public with sharing class ReconciliationReportController {

  public transient List<Affiliate_Yearly__c> listOfRecords { get; set; }
  public static String todayDate {get; set;}


  static {
    Datetime myDatetime = Datetime.now();
    todayDate = myDatetime.format('EEE MMM d,  yyyy');
  }

  public ReconciliationReportController() {
    listOfRecords = new List<Affiliate_Yearly__c>();
    //listOfRecords = [select from  ]
  }
  public PageReference redirectReconciliationReportUnion() {
    PageReference pageRef = null;
    String afID = ApexPages.currentPage().getParameters().get('afid');
    if (afID != null && afID != '') {
      Affiliate_Yearly__c affiliateYear = [SELECT ID, Eligible_for_GMI__c FROM Affiliate_Yearly__c WHERE ID = :afID LIMIT 1];
      if (affiliateYear.Eligible_for_GMI__c) {
        pageRef = new PageReference('/apex/Reconcile_UnionGMIReportPage?afid=' + afID);
      } else {
        pageRef = new PageReference('/apex/Reconcile_UnionNonGMIReportPage?afid=' + afID);
      }
    }
    return pageRef;
  }

  public PageReference redirectReconciliationReportFoundationGMI() {
    PageReference pageRef = null;
    String afID = ApexPages.currentPage().getParameters().get('afid');
    Affiliate_Yearly__c affiliateYear = [SELECT ID, Eligible_for_GMI__c FROM Affiliate_Yearly__c WHERE ID = :afID LIMIT 1];
    if (afID != null && afID != '') {
      if (affiliateYear.Eligible_for_GMI__c) {
        pageRef = new PageReference('/apex/Reconcile_FoundationGMIReportPage?afid=' + afID);
      } else {
        pageRef = new PageReference('/apex/Reconcile_FoundationNonGMIReportPage?afid=' + afID);
      }
    }
    return pageRef;
  }

}
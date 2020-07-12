/*
*
*Name  :  RevenueSharingShareCodes
*Author:  Appirio India (Sai Krishna)
*Date  :  December 2, 2016
*Purpose : Controller class for Revenue_Sharing_Admin Page
*          This page initiates CMI/FCMI/Donor Member Count revenue sharing calculations for Affiliate Yearly
*
*/
public with sharing class RevenueSharingAdminController {

    public Boolean isShowError { get; set; }

    public String foundationCostvalue { get; set; }

    public String unionCostvalue { get; set; }

    public String selectedReportType { get; set; }

    public Affiliate_Yearly__c affiliateYearly { get; set;}

    public Boolean isProcessing { get; set;}

    public Boolean isError { get; set; }
    
    public Id affiliateYearlyId {get;set;}
    
    public Boolean isDonorMemberCount {get;set;}
    
    public Boolean closeWindow{get;set;}

    public Revenue_Sharing_Sytem_Controls__c rSSC{get;set;}
    
    /*
    *Method save
    *@description : save the values and triggers the CMI calculations.
    */
    public void save() {


        List<Affiliate_Yearly__c> affs = new List<Affiliate_Yearly__c> ();
        if(validation()){
            isShowError = false;
            National_Fiscal_Year__c fiscalYearCustomSetting = National_Fiscal_Year__c.getAll().get(Utilities.getFiscalYearFromDate(affiliateYearly.CMI_stage_DateEnd__c));
            String fiscalYear = Utilities.getFiscalYearFromDate(affiliateYearly.CMI_stage_DateEnd__c);
            String query;
            if(selectedReportType == 'Donor-Member Count' && (ApexPages.currentPage().getParameters().get('affId'))!= null){
            	Id affId = (ApexPages.currentPage().getParameters().get('affId'));
            	query = 'SELECT Id, Foundation_Cost_Factor__c, Union_Cost_Factor__c FROM Affiliate_Yearly__c ';
            	query+= 'WHERE Id=:affId';
            }
            else{
            	query = 'SELECT Id, Foundation_Cost_Factor__c, Union_Cost_Factor__c FROM Affiliate_Yearly__c ';
            	query+= 'WHERE Fiscal_Year__c =:fiscalYear';
            }
            

            // update the on affiliateYearly records
            for(Affiliate_Yearly__c aff: Database.query(query)){ 

                Affiliate_Yearly__c newAff = new Affiliate_Yearly__c (Id = aff.Id
                                                                    , Foundation_Cost_Factor__c = affiliateYearly.Foundation_Cost_Factor__c
                                                                    , Union_Cost_Factor__c = affiliateYearly.Union_Cost_Factor__c);
                if(selectedReportType == 'CMI'){
                    newAff.CMI_stage_DateStart__c = affiliateYearly.CMI_stage_DateStart__c;
                    newAff.CMI_stage_DateEnd__c = affiliateYearly.CMI_stage_DateEnd__c;
                } else if(selectedReportType == 'FCMI') {
                    newAff.FCMI_stage_DateStart__c = affiliateYearly.CMI_stage_DateStart__c;
                    newAff.FCMI_stage_DateEnd__c = affiliateYearly.CMI_stage_DateEnd__c;
                }
                else{
                	newAff.Member_Donor_Count_From_Date__c = affiliateYearly.CMI_stage_DateStart__c;
                    newAff.Member_Donor_Count_To_Date__c = affiliateYearly.CMI_stage_DateEnd__c;
                }
                affs.add(newAff);
            }
            if(!affs.IsEmpty()){
                //update the custom setting with the UnioncostFactor.
                if(fiscalYearCustomSetting != null){
                    update new National_Fiscal_Year__c(Id = fiscalYearCustomSetting.Id, Foundation_Cost_Factor__c = affiliateYearly.Foundation_Cost_Factor__c,  Union_Cost_Factor__c = affiliateYearly.Union_Cost_Factor__c  );
                }

                //rSSC = Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0];
                try{
                    update new Revenue_Sharing_Sytem_Controls__c (Id = rSSC.Id, Report_Request_Owner_Email__c = UserInfo.getUserEmail(), Report_Request_In_Progress__c = true, Salesforce_Base_URL__c = URL.getSalesforceBaseUrl().toExternalForm(),
                            Last_Run_Details__c = selectedReportType+' Report', Last_Start_Run_DateTime__c = system.now(), Last_User_Running_Report__c = UserInfo.getName());
                    
                    rSSC = Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0];
                    update affs;
                } catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('RevenueSharingAdminController','save',e.getMessage());
                    log.logException(e);
                    log.saveLogs();
                }
                if(selectedReportType != 'Donor-Member Count'){
                	RevSharing_StageReportCalculations.generateCMI_FCMI_Report(affs, selectedReportType);
                }else{
                	set<Id> affiliateYearlyIds = new set<Id>();
                	for(Affiliate_Yearly__c objAff: affs){
                		affiliateYearlyIds.add(objAff.Id);
                	}
                	// calling batch class to execute the member_Donor count
                	Member_Donor_Count_Calc batch = new Member_Donor_Count_Calc(new Set<Id>(affiliateYearlyIds));
                	Database.executeBatch(batch,2000);
                	if(affiliateYearlyId != null) {
                	    closeWindow = true;
                	}
                }
            }
            isError = false;
            isProcessing = true;
        }
    }
    

    /*
    *Method RevenueSharingAdminController
    *@description : Class Controller.
    */
    public RevenueSharingAdminController () {
        isError = true;
        isShowError = false;
        affiliateYearly = new Affiliate_Yearly__c ();
        isProcessing = Revenue_Sharing_Sytem_Controls__c.getAll().values()[0].Report_Request_In_Progress__c;
        selectedReportType=(ApexPages.currentPage().getParameters().get('affId'))!= null? 'Donor-Member Count' :null;
        affiliateYearlyId = (ApexPages.currentPage().getParameters().get('affId'))!= null? (ApexPages.currentPage().getParameters().get('affId')) :null;
        isDonorMemberCount = (ApexPages.currentPage().getParameters().get('affId'))!= null? true:false;
        closeWindow = false;
        rSSC = Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0];
    }
     /*
    *Method validation
    *@description : Validates the Input fields
    */
    public Boolean validation(){
    	//FCMI/CMI report
        if(affiliateYearly.Foundation_Cost_Factor__c != null && affiliateYearly.Union_Cost_Factor__c != null && affiliateYearly.CMI_stage_DateEnd__c != null &&
            affiliateYearly.CMI_stage_DateStart__c != null && !isDonorMemberCount){
           
           if(affiliateYearly.Foundation_Cost_Factor__c <= 0 || affiliateYearly.Union_Cost_Factor__c <= 0) {
               isShowError = true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Foundation Cost Factor and Union Cost Factor must be greater than 0');
                ApexPages.addMessage(myMsg);
                return false;
           }
           if(affiliateYearly.CMI_stage_DateEnd__c <= Date.Today() && affiliateYearly.CMI_stage_DateEnd__c > affiliateYearly.CMI_stage_DateStart__c && affiliateYearly.CMI_stage_DateStart__c.monthsBetween(affiliateYearly.CMI_stage_DateEnd__c) <= 12){
                return true;
           }
           else{
                isShowError = true;
                closeWindow = false;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Start & End Date cannot be same, Date range must not exceed a 12 month period and the end date may not be in the future.');
                ApexPages.addMessage(myMsg);
                return false;
           }
       }
       //FCMI/CMI Report
       else if(!isDonorMemberCount && selectedReportType != 'Donor-Member Count'){
           system.debug('Error from here');
            isShowError = true;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'All fields are required');
            ApexPages.addMessage(myMsg);
            return false;
       }
       // DonorMemberCount
       else {
       		if(affiliateYearly.CMI_stage_DateEnd__c <= Date.Today() && affiliateYearly.CMI_stage_DateEnd__c > affiliateYearly.CMI_stage_DateStart__c && affiliateYearly.CMI_stage_DateStart__c.monthsBetween(affiliateYearly.CMI_stage_DateEnd__c) <= 12){
       			return true;
       		}
       		else{
       			isShowError = true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Start & End Date cannot be same, Date range must not exceed a 12 month period and the end date may not be in the future.');
                ApexPages.addMessage(myMsg);
                return false;
       		}	
       }
    }
}
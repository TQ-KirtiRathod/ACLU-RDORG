/*
*
*Name  :  NationalBudgetReportController
*Author:  Appirio India (Sandeep Soni)
*Date  :  Jun 09, 2017
*Purpose : This controller class for NationalBudgetReport page is used for generating National Budget Report 
*          based on filter criteria(Current YTD Start, Current YTD End, Prior YTD Start, Prior YTD End).
*
*/
public class NationalBudgetReportController {

    //public National_Budget__c nb {get;set;} only needed if conversion to sf date picker
    public Date current_YTD_StartDate {get; set;}
    public Date current_YTD_EndDate {get; set;}
    public Date prior_YTD_StartDate {get; set;}
    public Date prior_YTD_EndDate {get; set;}
    public Boolean isShowError {get; set;}
    public String Prior_Fiscal_Year {get; set;}
    public String Budget_Fiscal_Year {get; set;}
    public static final String currFiscalYear {get; set;}
    public String c3NationBudgetReport {get; set;}
    public String c4NationBudgetReport {get; set;}
    public String nationBudgetSummaryReport {get; set;}
    public String nationBudgetUnbudgetGiftReport {get; set;}
    public Boolean isRecordExist {get; set;}

    static {
        currFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name;
    }
    public String DefaultBudget_Fiscal_Year {get; set;}
    public String DefaultPrior_Fiscal_Year {get; set;}

    public NationalBudgetReportController() {
        //nb = new National_Budget__c(); only needed if conversion to sf date picker
        isRecordExist = false;
        if (DefaultBudget_Fiscal_Year == null) {
            DefaultBudget_Fiscal_Year = currFiscalYear;
        }
        if (DefaultPrior_Fiscal_Year == null) {
            DefaultPrior_Fiscal_Year = String.valueOf(Integer.valueOf(currFiscalYear) - 1);
        }
    }
    public List<SelectOption> getPriorFiscalYearOptions() {
        List<SelectOption> priorFiscalYearOptions = new List<SelectOption>();
        priorFiscalYearOptions.add(new SelectOption('2015', '2015'));
        priorFiscalYearOptions.add(new SelectOption('2016', '2016'));
        priorFiscalYearOptions.add(new SelectOption('2017', '2017'));
        priorFiscalYearOptions.add(new SelectOption('2018', '2018'));
        priorFiscalYearOptions.add(new SelectOption('2019', '2019'));
        priorFiscalYearOptions.add(new SelectOption('2020', '2020'));
        priorFiscalYearOptions.add(new SelectOption('2021', '2021'));
        priorFiscalYearOptions.add(new SelectOption('2022', '2022'));
        priorFiscalYearOptions.add(new SelectOption('2023', '2023'));
        priorFiscalYearOptions.add(new SelectOption('2024', '2024'));
        priorFiscalYearOptions.add(new SelectOption('2025', '2025'));
        return priorFiscalYearOptions;
    }
    public List<SelectOption> getBudgetFiscalYearOptions() {
        List<SelectOption> budgetFiscalYearOptions = new List<SelectOption>();
        budgetFiscalYearOptions.add(new SelectOption('2015', '2015'));
        budgetFiscalYearOptions.add(new SelectOption('2016', '2016'));
        budgetFiscalYearOptions.add(new SelectOption('2017', '2017'));
        budgetFiscalYearOptions.add(new SelectOption('2018', '2018'));
        budgetFiscalYearOptions.add(new SelectOption('2019', '2019'));
        budgetFiscalYearOptions.add(new SelectOption('2020', '2020'));
        budgetFiscalYearOptions.add(new SelectOption('2021', '2021'));
        budgetFiscalYearOptions.add(new SelectOption('2022', '2022'));
        budgetFiscalYearOptions.add(new SelectOption('2023', '2023'));
        budgetFiscalYearOptions.add(new SelectOption('2024', '2024'));
        budgetFiscalYearOptions.add(new SelectOption('2025', '2025'));
        return budgetFiscalYearOptions;
    }
    public void showReport() {
        Budget_Fiscal_Year = DefaultBudget_Fiscal_Year;
        Prior_Fiscal_Year = DefaultPrior_Fiscal_Year;
        //custom settign called 'national budget report status'
        National_Budget_Report_Status__c nbrs = National_Budget_Report_Status__c.getOrgDefaults();
        System.debug('in controller flag: '+nbrs.Report_Request_In_Progress__c);
        if (current_YTD_StartDate == null || current_YTD_EndDate == null || prior_YTD_StartDate == null
                || prior_YTD_EndDate == null || Prior_Fiscal_Year == null || Budget_Fiscal_Year == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'Enter all filter criteria'));
            isRecordExist = false;
            return;
        } else if (current_YTD_StartDate > current_YTD_EndDate || prior_YTD_StartDate > prior_YTD_EndDate) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'Start Dates can not be before End Dates'));
            isRecordExist = false;
            return;
        } else if (nbrs.Report_Request_In_Progress__c) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'This Report is already requested from another user, Please wait or try after some time.'));
            isRecordExist = false;
            return;
        } else {
            try {
                BatchOnNationalBudgetDelete bnbDelete = new BatchOnNationalBudgetDelete();
                bnbDelete.current_YTD_StartDate = current_YTD_StartDate;
                bnbDelete.current_YTD_EndDate = current_YTD_EndDate;
                bnbDelete.prior_YTD_StartDate = prior_YTD_StartDate;
                bnbDelete.prior_YTD_EndDate = prior_YTD_EndDate;
                bnbDelete.budgetFiscalYear = Integer.valueOf(Budget_Fiscal_Year);
                bnbDelete.priorFiscalYear = Integer.valueOf(Prior_Fiscal_Year);
                Database.executeBatch(bnbDelete,2000);
                isRecordExist = true;
            } catch (Exception e) {
                System.debug('IO Error:' + e.getMessage());
            }
            
        }
    }
}
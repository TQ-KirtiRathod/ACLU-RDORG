/*
*
*Name  :  CampaignPerformanceReportingController
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  April 13, 2017
*Purpose : Controller class for CampaignPerformanceReportingPage
*          The page is a custom VF report for daily campaign performance
*
*/
public class CampaignPerformanceReportingController {
    transient public list<ReportWrapper> repWrapper{get;set;}
    transient public list<ChartWrapper> cWrapper{get;set;}
    public static final STring ERROR_MESSAGE = 'Number of records are too large to be displayed.';
    public Boolean showButton{get;set;}
    public CampaignPerformanceReportingController() {
        
    }
    public void displayReport() {
        showButton = false;
        list<AggregateResult> aggResult = new list<AggregateResult>();
        try{
            for (AggregateResult agg : [Select closedate, count(Id) totalCount, sum(rC_Giving__Giving_Amount__c) totalAmount 
                                            From Opportunity where Campaign.rC_Giving__Affiliation__c = :ApexPages.currentPage().getParameters().get('pv1')
                                            AND Campaign.rC_Giving__Sub_Affiliation__c  = :ApexPages.currentPage().getParameters().get('pv2')
                                            AND Campaign.rC_Giving__Campaign_Type__c = :ApexPages.currentPage().getParameters().get('pv3')
                                            AND Campaign.rC_Giving__Appeal_Segment__c = :ApexPages.currentPage().getParameters().get('pv4')
                                            AND Campaign.rC_Giving__Solicitation_Type__c = :ApexPages.currentPage().getParameters().get('pv5')
                                            AND Campaign.rC_Giving__Channel__c = :ApexPages.currentPage().getParameters().get('pv6')
                                            AND Campaign.rC_Giving__Effort__c = :ApexPages.currentPage().getParameters().get('pv7')
                                            AND (RecordType.name = 'Donation' OR RecordType.name = 'Pledge')
                                            group by closedate 
                                            order by closedate]) {
            aggResult.add(agg);
        }
        } catch(Exception ex) {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.WARNING,ERROR_MESSAGE);
            ApexPages.addMessage(errorMsg);
            return;
        }
     
        //logic to find max and min close dates
        showButton = true;
        Date minDate;
        if(aggResult.size() > 1) {
            minDate = (Date)aggResult.get(0).get('closeDate');
        }
        ReportWrapper rw;
        repWrapper = new list<ReportWrapper>();
        cWrapper = new list<ChartWrapper>();
        Double cmAmt = 0;
        Integer cmCount = 0;
        for(AggregateResult agg : aggResult) {
            if(minDate == null) {//If there is one record in report
                rw = new ReportWrapper();
                rw.closeDate = (Date)agg.get('closedate');
                rw.amount = (Double)agg.get('totalAmount');
                rw.count = (Integer)agg.get('totalCount');
                if(rw.amount != null) {
                    cmAmt += rw.amount;
                }
                cmCount += rw.count;
                rw.cumulativeAmt = cmAmt;
                rw.cumulativeCount = cmCount;
                //cWrapper.add(new ChartWrapper(String.valueOf(rw.closeDate), rw.cumulativeAmt, rw.cumulativeCount));
                cWrapper.add(new ChartWrapper(String.valueOf(rw.closeDate), rw.cumulativeAmt));
                rw.cDate = String.valueOf(rw.closeDate);
                repWrapper.add(rw);
                break;
            }
            if(minDate != (Date)agg.get('closedate')) {
                for(Date d = minDate.addDays(1); d < (Date)agg.get('closedate'); d = d.addDays(1)) {
                    rw = new ReportWrapper();
                    rw.closeDate = d;
                    rw.amount = 0;
                    rw.count = 0;
                    rw.cumulativeAmt = cmAmt;
                    rw.cumulativeCount = cmCount;
                    rw.cDate = String.valueOf(rw.closeDate);
                    repWrapper.add(rw);
                }
            }
            rw = new ReportWrapper();
            rw.closeDate = (Date)agg.get('closedate');
            rw.amount = (Double)agg.get('totalAmount');
            rw.count = (Integer)agg.get('totalCount');
            if(rw.amount != null) {
                cmAmt += rw.amount;
            }
            cmCount += rw.count;
            rw.cumulativeAmt = cmAmt;
            rw.cumulativeCount = cmCount;
            //cWrapper.add(new ChartWrapper(String.valueOf(rw.closeDate), rw.cumulativeAmt, rw.cumulativeCount));
            cWrapper.add(new ChartWrapper(String.valueOf(rw.closeDate), rw.cumulativeAmt));
            rw.cDate = String.valueOf(rw.closeDate);
            repWrapper.add(rw);
            
            minDate = (Date)agg.get('closedate');
            
        }
    }
    
    public PageReference displayExcel() {
        PageReference pg = new PageReference('/apex/CampaignPerformanceRatingExcel?pv0='+ApexPages.currentPage().getParameters().get('pv0')+
                                '&pv1=' + ApexPages.currentPage().getParameters().get('pv1') +
                                '&pv2=' + ApexPages.currentPage().getParameters().get('pv2') +
                                '&pv3=' + ApexPages.currentPage().getParameters().get('pv3') +
                                '&pv4=' + ApexPages.currentPage().getParameters().get('pv4') +
                                '&pv5=' + ApexPages.currentPage().getParameters().get('pv5') +
                                '&pv6=' + ApexPages.currentPage().getParameters().get('pv6') +
                                '&pv7=' + ApexPages.currentPage().getParameters().get('pv7'));
        return pg;
    }
    public class ReportWrapper {
        public Date closeDate{get;set;}
        public Double amount{get;set;}
        public Integer count{get;set;}
        public Double cumulativeAmt{get;set;}
        public Integer cumulativeCount{get;set;}
        public String cDate{get;set;}
        public ReportWrapper() {
            amount = 0;
            count = 0;
            cumulativeAmt = 0;
            cumulativeCount = 0;
        }
    }
    
    public class ChartWrapper{
        public String dateField { get; set; }
        public Double amountField { get; set; }
        //public Integer countfield { get; set; }
        public ChartWrapper(String dateField, Double amountField) {
            this.dateField = dateField;
            this.amountField = amountField;
            //this.countfield = countfield;
        }
    }
}
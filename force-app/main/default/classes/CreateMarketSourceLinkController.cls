/*
*
*Name  :  CreateMarketSourceLinkController
*Author:  ACLU (David Reed)
*Date  :  May 23, 2017
*Purpose : Controller class for CreateMarketSourceLink. This page generates a string used for Market Source Links
*
*/
public with sharing class CreateMarketSourceLinkController {
	public String link { get; set; }
    public String marketSource { get; set; }
    public String affiliate { get; set; }
    public String external { get; set; }
    public String finalLink { get; private set; }

    static final List<List<String>> channels = new List<List<String>>{
        new List<String> {'web', 'Web'},
        new List<String> {'eml', 'Email'},
        new List<String> {'fb', 'Facebook'},
        new List<String> {'tw', 'Twitter'},
        new List<String> {'gad', 'Ads'},
        new List<String> {'ptp', 'Peer to Peer'},
        new List<String> {'', 'Others'}
    };

    @TestVisible
    private class InvalidURLParameterException extends Exception {}
    @TestVisible
    private class MissingURLParameterException extends Exception {}

    public CreateMarketSourceLinkController() {
		
	}

    public List<SelectOption> getAffiliateOptions() {
        List<SelectOption> affiliations = new List<SelectOption>();

        affiliations.add(new SelectOption('NAT', 'National'));

        for (Schema.PicklistEntry p : User.Primary_Affiliate__c.getDescribe().getPicklistValues()) {
            if (p.isActive()) {
                affiliations.add(new SelectOption(p.getValue().left(2), p.getLabel()));
            }
        }

        return affiliations;
    }


    public PageReference updateURL() {
        finalLink = '';

        try {
            for (List<String> chan : channels) {
                if (!String.isBlank(finalLink)) 
                    finalLink += '\n\n';
                finalLink += chan[1];
                finalLink += ': ';
                finalLink += generateMarketSourceURL(link, marketSource, chan[0], affiliate, external);
            }
        } catch (InvalidURLParameterException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                       'International or non-printable characters are not supported in your parameters.'));
        } catch (MissingURLParameterException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                       'Please provide a base URL and select an affiliate.'));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                       'A URL could not be created. Please check your input.'));
        }

        return null;
    }

    @TestVisible
    private static String generateMarketSourceURL(String base, String marketSource, String channel, String affiliate, String external) {
        String queryString = '?';

        if (String.isBlank(base) || String.isBlank(affiliate))
            throw new MissingURLParameterException();

        if (!base.startsWith('http://') && !base.startsWith('https://'))
            base = 'http://' + base.trim();

        if (String.isBlank(new URL(base).getFile()))
            base += '/';
//`initms`, `initms_aff`, `initms_chan`, and `initms_ex`.
         if (!String.isBlank(affiliate)) {
             if (affiliate.isAsciiPrintable()) {
                queryString += 'ms_aff=' + EncodingUtil.urlEncode(affiliate.trim(), 'UTF-8');
                queryString += '&initms_aff=' + EncodingUtil.urlEncode(affiliate.trim(), 'UTF-8');
            } else {
                throw new InvalidURLParameterException();
            }
        }

        if (!String.isBlank(marketSource)) {
            if (marketSource.isAsciiPrintable()) {
                queryString += '&ms=' + EncodingUtil.urlEncode(marketSource.trim(), 'UTF-8');
                queryString += '&initms=' + EncodingUtil.urlEncode(marketSource.trim(), 'UTF-8');
            } else {
                throw new InvalidURLParameterException();
            }
        }

        if (!String.isBlank(channel)) {
            if (channel.isAsciiPrintable()) {
                queryString += '&ms_chan=' + EncodingUtil.urlEncode(channel.trim(), 'UTF-8');
                queryString += '&initms_chan=' + EncodingUtil.urlEncode(channel.trim(), 'UTF-8');
            } else {
                throw new InvalidURLParameterException();
            }
        }

        if (!String.isBlank(external)) {
             if (external.isAsciiPrintable()) {
                queryString += '&ms_ex=' + EncodingUtil.urlEncode(external.trim(), 'UTF-8');
                queryString += '&initms_ex=' + EncodingUtil.urlEncode(external.trim(), 'UTF-8');
            } else {
                throw new InvalidURLParameterException();
            }
        }

        return new URL(base + queryString).toExternalForm();
    }

}
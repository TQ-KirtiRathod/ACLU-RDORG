/*
*
*Name  :  CreateMarketSourceLinkControllerTEST
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test CreateMarketSourceLinkController Class functionality
*
*/
@isTest
private class CreateMarketSourceLinkControllerTEST {
	
	@isTest static void testGetAffiliateOptions() {
		List<SelectOption> sos = new CreateMarketSourceLinkController().getAffiliateOptions();

        // Ensure the list of affiliates is of the right magnitude.
        System.assert(sos.size() > 50);
        // We add the National entry.
        System.assertEquals('NAT', sos[0].getValue());
	}

    @isTest static void testUpdateURLSuccess() {
        CreateMarketSourceLinkController c = new CreateMarketSourceLinkController();

        c.link = 'test.com';
        c.marketSource = 'marketSource';
        c.affiliate = 'NAT';
        c.external = 'external';

        c.updateURL();

        System.assert(c.finalLink.length() > 'http://test.com/?ms_aff=NAT&ms=marketSource&ms_chan=fb&ms_ex=external'.length());
    }

    @isTest static void testUpdateURLFailMissingParam() {
        CreateMarketSourceLinkController c = new CreateMarketSourceLinkController();

        c.link = 'test.com';
        c.marketSource = 'marketSource';
        c.external = 'external';

        c.updateURL();

        System.assert(ApexPages.getMessages().size() > 0);
    }

    @isTest static void testUpdateURLFailBadParam() {
        CreateMarketSourceLinkController c = new CreateMarketSourceLinkController();

        c.link = 'test.com';
        c.affiliate = 'NAT';
        c.marketSource = 'Σωκράτης';
        c.external = 'external';

        c.updateURL();

        c.link = 'test.com';
        c.affiliate = 'Σωκράτης';
        c.marketSource = 'ms';
        c.external = 'external';

        c.updateURL();

        c.link = 'test.com';
        c.affiliate = 'NAT';
        c.marketSource = 'ms';
        c.external = 'Σωκράτης';

        c.updateURL();

        System.assert(ApexPages.getMessages().size() > 0);
    }
	
	@isTest static void testGenerateMarketSourceURL() {
        // Test some cases with URL parsing
        System.assertEquals('http://test.com/?ms_aff=NAT&initms_aff=NAT&ms_chan=web&initms_chan=web', 
            CreateMarketSourceLinkController.generateMarketSourceURL('test.com', '', 'web', 'NAT', ''));
        System.assertEquals('http://test.com/?ms_aff=NAT&initms_aff=NAT&ms_chan=web&initms_chan=web', 
            CreateMarketSourceLinkController.generateMarketSourceURL('test.com/', '', 'web', 'NAT', ''));
        System.assertEquals('http://test.com/q?ms_aff=NAT&initms_aff=NAT&ms_chan=web&initms_chan=web', 
            CreateMarketSourceLinkController.generateMarketSourceURL('test.com/q', '', 'web', 'NAT', ''));
        System.assertEquals('http://test.com/?ms_aff=NAT&initms_aff=NAT&ms_chan=web&initms_chan=web', 
            CreateMarketSourceLinkController.generateMarketSourceURL('http://test.com', '', 'web', 'NAT', ''));
        System.assertEquals('https://test.com/?ms_aff=NAT&initms_aff=NAT&ms_chan=web&initms_chan=web', 
            CreateMarketSourceLinkController.generateMarketSourceURL('https://test.com', '', 'web', 'NAT', ''));

        // Test the population of all four codes.
        System.assertEquals('http://test.com/?ms_aff=NAT&initms_aff=NAT&ms=TMS&initms=TMS&ms_chan=web&initms_chan=web&ms_ex=TEX&initms_ex=TEX', 
            CreateMarketSourceLinkController.generateMarketSourceURL('test.com', 'TMS', 'web', 'NAT', 'TEX'));

        // Test error handling
        Exception e;

        // Missing parameters
        try {
            CreateMarketSourceLinkController.generateMarketSourceURL('', '', '', '', '');
        } catch (Exception e2) {
            e = e2;
        }

        System.assert(e != null);

        e = null;
        // Bad input.
        try {
            CreateMarketSourceLinkController.generateMarketSourceURL('test.com', 'Σωκράτης', '', '', '');
        } catch (Exception e2) {
            e = e2;
        }

        System.assert(e != null);

	}
	
}
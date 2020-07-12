/*
*
*Name  :  CalloutMergeEmail
*Author:  Appirio India (Lalit Bohra)
*Date  :  June 21, 2017
*Purpose : Class to generate mock response use for test classes
*
*/
global class CalloutMergeEmail implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest r) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('http://api.salesforce.com/foo/bar');
        req.setMethod('POST');
     
         HttpResponse res = new HttpResponse();
    	 res.setHeader('Content-Type', 'application/json');
    	 res.setBody('{"status":"success"}');
    	 res.setStatusCode(200);
    	 return res; 
    }

}
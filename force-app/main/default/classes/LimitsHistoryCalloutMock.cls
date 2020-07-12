/*
*
*Name  :  LimitsHistoryCalloutMock
*Author:  Appirio India (Lalit Bohra)
*Date  :  July 17, 2017
*Purpose : Class to generate mock response
*
*/
@isTest
public class LimitsHistoryCalloutMock implements HttpCalloutMock {

    protected Integer code;
    protected String status;
    protected String body;
    protected Map<String, String> responseHeaders;

    public LimitsHistoryCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.body = body;
        this.responseHeaders = responseHeaders;
    }

    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        for (String key : this.responseHeaders.keySet()) {
            res.setHeader(key, this.responseHeaders.get(key));
        }
        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }

}
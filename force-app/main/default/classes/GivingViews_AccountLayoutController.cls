/*
*
*Name  :  GivingViewsAccountLayoutController
*Author:  Appirio India (Sai Krishna )
*Date  :  March 06, 2017
*Purpose : Controller for the GivingViews_AccountLayout
*
*/
public with sharing class GivingViews_AccountLayoutController {
    public ID accountId {get;set;}
    //Constructor
	public GivingViews_AccountLayoutController(ApexPages.StandardController controller) {
        Account acc = new Account();
        accountId = controller.getId();
    } 
}
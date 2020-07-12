/*@description: This script will insert a modal div in the standard page.
                the modal will contain a VF page. This file should be located in static resource.*/
var j$ = jQuery.noConflict();
var currentUrl = window.location.href;
var hostIndex = currentUrl.indexOf(window.location.host+'/')+(window.location.host+'/').length;
var accountId = "001W000000QGamz"; 
j$(function(){
    /*Insert the jQuery style sheets in the Head.*/
    /*Insert the Modal dialog along with the VF as an iframe inside the div.*/
    j$("head").after(
        j$("<link>",{rel:"stylesheet",
                    href:"https://code.jquery.com/ui/1.10.4/themes/smoothness/jquery-ui.css"}));
    j$("body").after(
        j$("<div>",{id:"modalDiv",
                    style:"display:none;"
           }).append(
            j$("<iframe>",{id:"vfFrame",
                         src:"/apex/AccountDetailPage?id="+accountId,
                         height:500,
                         width:1000,
                         frameBorder:0})
           ));
    /*Initialize the Dialog window.*/
    j$("#modalDiv").dialog({
        autoOpen: false,
        height: 500,
        width: 1000,
		draggable: true,
		resizeable: true,
        modal:true
    });
});
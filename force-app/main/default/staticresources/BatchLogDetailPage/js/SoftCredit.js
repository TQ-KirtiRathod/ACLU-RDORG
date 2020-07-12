window._bge = (function() {
  var grid = jQuery('#bgeList');
  
  var reloadGrid = function(expandLast) {
    console.log("reloadGrid");
    console.log("_bge.isSave", _bge.isSave);
    console.log("_bgeApex.isError",_bgeApex.isError);
    if (_bge.isSave && _bgeApex.isError) {
      _bge.isSave = false;
      return;
    }
    var tmpId = _bge.prevActiveRowId;
    _bge.prevActiveRowId = '';
    _bge.origFormState = '';
    detailSection('hide');
    console.log(_bgeApex.opportunityList);
    grid.jqGrid('clearGridData').jqGrid('setGridParam', {data: _bgeApex.opportunityList}).trigger('reloadGrid');
    if (expandLast !== false) {
      grid.setSelection(tmpId);
    }
    _bge.isSave = false;
  }
  
  var showOpptDetail = function(){
    // Hide loader and show the refreshed details block
    detailLoader('hide');
    detailSection("show");

    var rowIndex = Number(_bge.prevActiveRowId.substring(3)) - 1;
    if (_bgeApex.opportunityList.length > rowIndex && _bgeApex.opportunityList[rowIndex]["isNew"]) {
      _bge.origFormState = "new";
    } else {
      _bge.origFormState = serializeForm();
    }
    
    resizeWindow();

    jQuery('html, body').animate({
      scrollTop: jQuery("#" + _bge.prevActiveRowId).offset().top - vfElement('hardCreditSection').outerHeight()
    }, 1000);

    try {
      if (vfElement("accountNumber")[0] && vfElement("accountNumber")[0].focus) {
        vfElement("accountNumber")[0].focus();
      }
    } catch (err) {
      console.log("Can't focus on amount!");
    }
  }
  
  var serializeForm = function() {
    // Take a serialized copy of the form variables to be able to determine later if any fields were changed
    return jQuery( ".bldp-custom-oppt-detail input, .bldp-custom-oppt-detail textarea, .bldp-custom-oppt-detail select" ).serialize()
  }
  
  var collapseSections = function(){
    // Collapse the required sections by default while displaying the details block
    jQuery("*[data-collapse='true']").each(function() {
      twistSection(this.getElementsByTagName('img')[0]) ;
    });
  }
  
  var detailSection = function(showHide) {
    if (showHide === "hide") {
      // Move the detail block to the original parent (hidden, outside the grid)
      jQuery(".bldp-custom-oppt-container").append( jQuery(".bldp-custom-oppt-block") );
    }
    jQuery(".bldp-custom-oppt-detail")[showHide]();
  }
  
  var detailLoader = function(showHide) {
    // Show or Hide the loader
    jQuery(".bldp-custom-oppt-loader")[showHide]();
  }
  
  var isUnsavedRow = function(){
    return ("" !== _bge.origFormState && serializeForm() !== _bge.origFormState);
  }
  
  var cancelChange = function(){
    // Check the current state of the form fields and compare with the original state
    // If changes are found, confirm action with the user
    var isFormChanged = _bge.isUnsavedRow();
    if (isFormChanged) {
      var r = confirm("Are you sure you want to cancel? Changes you have made to this row will be lost.");
      if (!r) {
        return;
      }
    }
    detailSection('hide');

    // Collapse the row and remove selection
    grid.collapseSubGridRow(_bge.prevActiveRowId).resetSelection();

    if (isFormChanged) {
      // Refresh from server
      cancelRowChange();
    } else {
      _bge.prevActiveRowId = "";
      _bge.origFormState = "";
    }
  }
  
  var saveOppt = function(){
    _bge.isSave = true;
    saveOneRow();
  }
  
  var saveAndValidate = function(){
    _bge.isSave = true;
    saveAndValidateAmount();
  }
  
  var confirmSaveBeforeAction = function(insideRow) {
    var msg;
    if (insideRow) {
      msg = "This row has unsaved data!";
    } else {
      var rowNum = _bge.prevActiveRowId.substring(3);
      msg = "Row # " + rowNum + " has unsaved data!";
    }
    msg += "\n\nPress OK to save the row and proceed. Otherwise, press Cancel to abort and return to editing the row.";
    _bge.isInterimSave = confirm(msg);
    return _bge.isInterimSave;
  }

  var addRow = function() {
    if (_bge.isUnsavedRow()) {
      // Mark next action to be performed after successful save
      _bge.finalAction = "ADD_ROW";
      _bge.isInterimSave = true;
      // Initiate Save
      saveOppt();
    } else {
      addChildRows();
    }
  }
  
  var exportItems = function() {
    if (_bge.isUnsavedRow()) {
      if (confirmSaveBeforeAction()) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "EXPORT_ITEMS";
        // Initiate Save
        saveOppt();
      }
    } else {
      exportSoftCredit();
    }
  }
  
  var afterSaveRow = function() {
    console.log("afterSaveRow");
    console.log("_bge.isSave", _bge.isSave);
    console.log("_bgeApex.isError",_bgeApex.isError);
    if (_bge.isInterimSave) {
      _bge.reloadGrid(false);
      if (_bgeApex.isError) {
        alert("An error occurred while saving! Please fix the error(s) before proceeding.");
      } else {
        if (_bge.finalAction === "ADD_ROW") {
          addChildRows();
        } else if (_bge.finalAction === "EXPORT_ITEMS") {
          exportSoftCredit();
        }
      }
      _bge.isInterimSave = false;
      _bge.finalAction = "";
      _bge.actionParams = {};
    } else {
      _bge.reloadGrid();
    }
  }
  
  var afterAddRow = function() {
    _bge.reloadGrid(false);
    var rowCount = _bgeApex.opportunityList.length;
    grid.setSelection(gridIdPrefix + (rowCount));
  }
  
  // Soft Credit Save and Close
  var afterValidateAmount = function() {
    if (_bgeApex.isError) {
      alert("An error occurred while saving! Please fix the error(s) before proceeding.");
      _bge.reloadGrid();
    } else {
      if (!_bgeApex.isMatchingAmount) {
        var r = confirm("Total Amount of Soft Credit(s) does not match with Hard Credit Amount. Are you sure you want to close the window?");
        if (!r) {
          _bge.reloadGrid();
          return;
        }
      }
      console.log("afterValidateAmount");
      _bgeApex.isChanged = true;
      var winMain = window.opener || window.parent.opener;
      if (winMain) {
        winMain.closeSoftCreditPopup();
      }
    }
  }
  
  var toggleBackdrop = function(showHide) {
    if (jQuery("#el_loading").parent()) {
      jQuery("#el_loading").parent()[showHide]();
    }
  }
  
  var formatLinkCell = function (value, id) {
    var cellText = (value === undefined || value === null) ? "" : value;
    var targetId = (id === undefined || id === null) ? "" : id;
    if (cellText === "" || targetId === "") {
      return cellText;
    } else {
      return "<a href='/" + targetId + "' target='_blank'>" + cellText + "</a>";
    }
  }
  
  var colModel = [
    { label: "Account #",
      name: "objOppty.Account_Number_BGE__c",
      width: 20,
      sortable: false },

    { label: "Account Name",
      name: "accountName",
      width: 35,
      formatter: function (cellValue, options, rowObject) {
        return formatLinkCell(cellValue, rowObject.objOppty.AccountId);
      },
      sortable: false },

    { label: "Giving Record Type",
      name: "selectedRT",
      width: 30,
      sortable: false },

    { label: "Soft Credit Type",
      name: "objOppty.Soft_Credit_Type__c",
      width: 30,
      sortable: false },

    { label: "Amount",
      name: "objOppty.Amount",
      width: 20,
      formatter: 'currency',
      formatoptions: {
        decimalSeparator:".",
        thousandsSeparator: ",",
        decimalPlaces: 2,
        prefix: "$"
      },
      sortable: false },

    { label: "Source Code",
      name: "objOppty.rC_Giving__Source_Code__c",
      width: 25,
      sortable: false },

    { label: "Sharing Code",
      name: "objOppty.Sharing_Code__c",
      width: 25,
      sortable: false },

    { label: "Sharing Entity",
      name: "objOppty.Sharing_Entity__c",
      width: 25,
      sortable: false },

    { label: "Proposals/Grants",
      name: "proposalName",
      width: 30,
      sortable: false }
  ];

  var gridIdPrefix = "jqr";
  
  var onSelectRow = function(row_id) {
    var grid = jQuery(this);
    if (row_id !== _bge.prevActiveRowId) {
      // Check if another row is getting updated already and prompt for error
      if (_bge.isUnsavedRow()) {
        var oldRowNum = _bge.prevActiveRowId.substring(3);
        alert("Please save/cancel changes to row # " + oldRowNum + " first.");
        // Revert the row selection to highlight the row that is being updated already
        grid.setSelection(_bge.prevActiveRowId, false);
        return;
      }

      // Collapse prevously exanded row
      detailSection('hide');
      grid.collapseSubGridRow(_bge.prevActiveRowId);

      // Expand the clicked row
      grid.expandSubGridRow(row_id);
      _bge.prevActiveRowId = row_id;
      detailLoader('show');

      // Call the VF action function to refresh the detail block data
      var currRowIndex = Number(row_id.substring(3)) - 1;
      console.log("changeActiveOppt>>>", row_id);
      changeActiveOppt(currRowIndex);
    }
  }
  
  var resizeWindow = function () {
    jQuery(window).trigger('resize');
  }

  var onSubGridExpansion = function(subgrid_id, row_id) {
    // Move the detail block to the row that is being expanded
    jQuery("#" + subgrid_id).append( jQuery(".bldp-custom-oppt-block") );
    // Set the subgrid table cell to consume 100% avaialble width
    jQuery("#" + subgrid_id).closest("td").attr("colspan", "100%");
  }
  
  var autoResizeGridWithWindow = function() {
    // Auto-resize the grid when window width changes
    jQuery(window).bind('resize', function() {
      grid.setGridWidth(jQuery(window).width() - 28);
      vfElement('softCreditPopUp').css('padding-top', vfElement('hardCreditSection').outerHeight() + 'px');
    });
    resizeWindow();
  }
  
  jQuery(function () {
    grid.jqGrid({
      data: _bgeApex.opportunityList,
      datatype: "local",
      colModel: colModel,
      rowNum: 10000,
      pgbuttons: false,
      viewrecords: false,
      gridview: true,
      autoencode: true,
      autowidth: true,
      shrinkToFit: true,
      height: "auto",
      idPrefix: gridIdPrefix,
      subGrid: true,
      onSelectRow: onSelectRow,
      subGridRowExpanded: onSubGridExpansion,
      subGridRowColapsed: resizeWindow
    });
    // Hiding the +/- column in the row
    // is now done using CSS
    grid.jqGrid("hideCol", "subgrid");
    // Disable row selecion on right clicking the row
    grid.unbind("contextmenu");
    autoResizeGridWithWindow();
  });
  
  return { // public API
    prevActiveRowId: '',
    origFormState: '',
    finalAction: '',
    actionParams: {},
    isSave: false,
    isInterimSave: false,
    reloadGrid: reloadGrid,
    showOpptDetail: showOpptDetail,
    cancelChange: cancelChange,
    saveOppt: saveOppt,
    saveAndValidate: saveAndValidate,
    addRow: addRow,
    exportItems: exportItems,
    afterAddRow: afterAddRow,
    afterSaveRow: afterSaveRow,
    afterValidateAmount: afterValidateAmount,
    toggleBackdrop: toggleBackdrop,
    collapseSections: collapseSections,
    isUnsavedRow: isUnsavedRow
  }
}());

function vfElement(visualforceId) {
  return jQuery("[id $=':" + visualforceId + "']")
}

function vfId(visualforceId) {
  return vfElement(visualforceId).attr('id')
}

// ===============================================
// Legacy code
// ===============================================

//deleteRow
function deleteRow(rowIndex) {
  var r = confirm("This will delete this Giving record. Are you sure you want to proceed?");
  if (r == true) {
    deleteSoftCRow(rowIndex);
  } else {
    txt = "You pressed Cancel!";
  }
}

//softCreditGrants
function opensftGrants(row,accId,batchId,amountOrder){
  console.log('amountOrder',amountOrder);
  var amount;
  if (document.getElementById(vfId('recordAmt')) != null){
    amount= document.getElementById(vfId('recordAmt')).value;
  }
  console.log('amount',amount);
  openGrants(row,accId,amount,batchId,'','Soft Credit',true);
}

// Open Grants
function openGrants(row,accId,amount,batchId,payment,recordType,isSFT){
  var isPledge = (recordType == 'Pledge'?true:false)
  var url="/apex/BatchItem_Pledges_Proposal_Grants?accId="+accId+"&row="+row+"&bamount="+amount+"&batchId="+batchId+"&Payment="
    +payment+"&PP="+isPledge+"&isSC="+isSFT;
  newWin3=window.open(url, 'Popup','height=500,width=1000,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
  if (window.focus)
  {
    newWin3.focus();
  }
}

// updateParentOpp
function updateParentOpp(oppId,row,ispledge,openfromSft){
  _bge.isSave = true;
  modifyrow(row, oppId, ispledge,openfromSft);
}

// CloseAccLookupPopup
function closeAccLookupPopup(callImoFunction){
  if(null != newWin3){
    newWin3.close();
  }
}

//softcreditsAccountNumberChanged
function accountNumberChangedSoftCredit(row){
  var acctargetId = vfId('SoftcreditAccountlid');
  var acctargeName = vfId('SoftcreditAccount');
  var accNumberTargetId = vfId('accountNumber');
  var accNumberEle = document.getElementById(accNumberTargetId);
  var accId = accNumberEle.value;
  console.log('accId>>', accId);
  
  _bge.toggleBackdrop('show');
  Visualforce.remoting.Manager.invokeAction(
    _bgeRemoteAction.populateAccountLookup,
    row, accId,
    function(result, event){
      _bge.toggleBackdrop('hide');
      if (event.status) {
        if(result[0] != 'FaLsE'){
          console.log('RemotingResponse::', unescape(result[2]));
          console.log('RemotingResponse::Orgi:::', result[2]);
          document.getElementById(acctargeName).value = unescape(result[2]);
          document.getElementById(acctargetId).value = result[1];
          refreshTable(result[1], row);
        }
        else if(result[0] == 'FaLsE'){
          alert('Multiple accounts or no accounts found Please Select AccountId');
        }
      } else if (event.type === 'exception') {
        Console.log('Exception');
      } else {
        Console.log('Exception');
      }
    }, {escape: false, timeout: 30000}
  );
}

//Imo account Lookup
function imopassaccComponentIds (){
  var acctargetId = vfId('ImoacctargetId');
  var acctargeName = vfId('ImoacctargetName');
  var acctargeType = vfId('ImoacctargetType');
  
  var url="/apex/Account_Lookup_Page?namefield=" + acctargeName + "&idfield=" + acctargetId +"&imo=true"+"&accType="+acctargeType;
  newWin3=window.open(url, 'Popup','height=650,width=1000,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
  if (window.focus)
  {
    newWin3.focus();
  }
  return false;
}

function passaccComponentIds (row){
  var eleId = vfId('SoftcreditAccount');
  var lkId = vfId('SoftcreditAccountlid');
  var accTypeId = vfId('acctType');
  
  var url="/apex/Account_Lookup_Page?namefield=" + eleId + "&idfield=" + lkId +"&imo=false"+"&accType="+accTypeId+"&isSc=true&rownum="+row;
  newWin3=window.open(url, 'Popup','height=650,width=1000,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
  if (window.focus)
  {
    newWin3.focus();
  }
}

jQuery(window).bind('beforeunload', function() {
  console.log("beforeunload");
  var winMain = window.opener || window.parent.opener;
  if (winMain && _bgeApex.isChanged) {
    console.log("refreshing BGE opp list...");
    winMain.refreshList();
  }
});
var intervalHandle;
window._bge = (function() {
  var grid = jQuery('#bgeList');

  var reloadGrid = function(expandLast) {
    console.log("reloadGrid");
    console.log("_bge.isSave", _bge.isSave);
    console.log("_bgeApex.errorInBatchRow", _bgeApex.errorInBatchRow);
    console.log("_bgeApex.isError",_bgeApex.isError);
    if (_bge.isSave && _bgeApex.errorInBatchRow) {
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

    _bge.clearCustomInterval();
    var rowIndex = Number(_bge.prevActiveRowId.substring(3)) - 1;
    if (_bgeApex.opportunityList.length > rowIndex && _bgeApex.opportunityList[rowIndex]["isNew"]) {
      _bge.origFormState = "new";
    } else {
      _bge.origFormState = serializeForm();
      if (!_bgeApex.isReleased) {
        intervalHandle = _bge.setCustomInterval(_bge.toggleRowSaveButton, 1000);
      }
    }

    jQuery('html, body').animate({
      scrollTop: jQuery("#" + _bge.prevActiveRowId).offset().top
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
      _bge.clearCustomInterval();
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
      if (confirmSaveBeforeAction()) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "ADD_ROW";
        // Initiate Save
        saveOppt();
      }
    } else {
      addRowApex();
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
      exportBatchItems();
    }
  }

  var saveBatch = function() {
    if (_bge.isUnsavedRow()) {
      if (confirmSaveBeforeAction()) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "SAVE_BATCH_LOG";
        // Initiate Save
        saveOppt();
      }
    } else {
      saveBatchLog();
    }
  }

  var editBatch = function() {
    if (_bge.isUnsavedRow()) {
      if (confirmSaveBeforeAction()) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "EDIT_BATCH_LOG";
        // Initiate Save
        saveOppt();
      }
    } else {
      editBatchLog();
    }
  }

  var cancelBatch = function() {
    if (_bge.isUnsavedRow()) {
      if (confirmSaveBeforeAction()) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "CANCEL_BATCH_LOG";
        _bge.isEditBeforeCancel = _bgeApex.isEdit;
        // Initiate Save
        saveOppt();
      }
    } else {
      cancelBatchLog();
    }
  }

  var releaseBatch = function() {
    if (_bge.isUnsavedRow()) {
      if (confirmSaveBeforeAction()) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "RELEASE_BATCH_LOG";
        // Initiate Save
        saveOppt();
      }
    } else {
      releaseBatchLog();
    }
  }

  var addSplit = function(recCount) {
    if (_bge.isUnsavedRow()) {
      if (confirmSaveBeforeAction(true)) {
        // Mark next action to be performed after successful save
        _bge.finalAction = "ADD_SPLIT";
        _bge.actionParams = {"splitRowIndex": recCount};
        // Initiate Save
        saveOppt();
      }
    } else {
      addSplitRow(recCount);
    }
  }

  var openSoftCredit = function(OppId, batchId, isReleased) {
    if (_bge.isUnsavedRow()) {
      // Mark next action to be performed after successful save
      _bge.finalAction = "OPEN_SOFT_CREDIT";
      _bge.actionParams = {"OppId": OppId, "batchId": batchId, "isReleased": isReleased};
      _bge.isInterimSave = true;
      // Initiate Save
      saveOppt();
    } else {
      OpenSoftCreditGrid(OppId, batchId, isReleased);
    }
  }

  var afterSaveRow = function() {
    console.log("afterSaveRow");
    console.log("_bge.isSave", _bge.isSave);
    console.log("_bgeApex.errorInBatchRow", _bgeApex.errorInBatchRow);
    console.log("_bgeApex.isError",_bgeApex.isError);
    if (_bgeApex.errorInBatchRow) {
      if (_bge.isInterimSave) {
        alert("An error occurred while saving! Please fix the error(s) before proceeding.");
        _bge.isInterimSave = false;
        _bge.finalAction = "";
        _bge.actionParams = {};
      }
      _bge.reloadGrid();
      return;
    }
    createOpptyProducts();
  }

  var afterCreateOpptyProd = function() {
    console.log("afterCreateOpptyProd");
    console.log("_bge.isSave", _bge.isSave);
    console.log("_bgeApex.errorInBatchRow", _bgeApex.errorInBatchRow);
    console.log("_bgeApex.isError",_bgeApex.isError);
    if (_bge.isInterimSave) {
      if (_bge.finalAction === "OPEN_SOFT_CREDIT") {
        _bge.reloadGrid();
      } else {
        _bge.reloadGrid(false);
      }
      if (!_bgeApex.errorInBatchRow) {
        if (_bge.finalAction === "ADD_ROW") {
          addRowApex();
        } else if (_bge.finalAction === "EXPORT_ITEMS") {
          exportBatchItems();
        } else if (_bge.finalAction === "SAVE_BATCH_LOG") {
          saveBatchLog();
        } else if (_bge.finalAction === "EDIT_BATCH_LOG") {
          editBatchLog();
        } else if (_bge.finalAction === "CANCEL_BATCH_LOG") {
          if (!_bge.isEditBeforeCancel) {
            cancelBatchLog();
          }
        } else if (_bge.finalAction === "RELEASE_BATCH_LOG") {
          releaseBatchLog();
        } else if (_bge.finalAction === "ADD_SPLIT") {
          addSplitRow(_bge.actionParams["splitRowIndex"]);
        } else if (_bge.finalAction === "OPEN_SOFT_CREDIT") {
          if (_bge.actionParams["OppId"] === "" || _bge.actionParams["OppId"] === null) {
            var rowIndex = Number(_bge.prevActiveRowId.substring(3)) - 1;
            if (_bgeApex.opportunityList.length > rowIndex) {
              _bge.actionParams["OppId"] = _bgeApex.opportunityList[rowIndex]["objOppty"]["Id"];
            }
          }
          OpenSoftCreditGrid(_bge.actionParams["OppId"], _bge.actionParams["batchId"], _bge.actionParams["isReleased"]);
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

  var afterSplitRow = function() {
    _bge.reloadGrid(false);
    grid.setSelection(gridIdPrefix + _bgeApex.newSplitRowIndex);
  }

  var afterRefreshList = function() {
    if (_bge.exapandLastFlag) {
      _bge.reloadGrid();
    } else {
      _bge.reloadGrid(false);
    }
    _bge.exapandLastFlag = false;
  }

  var toggleBackdrop = function(showHide) {
    if (jQuery("#el_loading").parent()) {
      jQuery("#el_loading").parent()[showHide]();
    }
  }

  var focusOnGivingAmount = function() {
    try {
      var givingAmountField = vfElement("GivingAmountField");
      if (givingAmountField && givingAmountField.focus) {
        givingAmountField.focus();
      }
    } catch (err) {
        console.log("Can't focus on amount!");
    }
  }

  var focusOnSourceCode = function() {
    try {
      var sourceCodeField = vfElement("sourceCode");
      if (sourceCodeField && sourceCodeField.focus) {
        sourceCodeField.focus();
      }
    } catch (err) {
        console.log("Can't focus on source code!");
    }
  }

  var chooseGivingFrequency = function(givingFrequency) {
    var paymentFrequency = jQuery('.rC_Giving__Payment_Frequency__c').hide();
    var paymentCount = jQuery('.rC_Giving__Payment_Count__c').hide();
    var givingYears = jQuery('.rC_Giving__Giving_Years__c').hide();
    var paymentFrequencyField = jQuery('.rC_Giving__Payment_Frequency__c input, .rC_Giving__Payment_Frequency__c select');
    var paymentCountField = jQuery('.rC_Giving__Payment_Count__c input, .rC_Giving__Payment_Count__c select');
    var givingYearsField = jQuery('.rC_Giving__Giving_Years__c input, .rC_Giving__Giving_Years__c select');
    var showNothing = true;
    var fieldsFor = {
      "" : showNothing,
      "One Payment" : showNothing,
      "Irregular" : paymentCount,
      "Total" : paymentFrequency,
      "default" : givingYears
    };
    if (givingFrequency) {
      var currVal = givingFrequency.value;
      var fieldsToShow = (fieldsFor[currVal] || fieldsFor.default);
      fieldsToShow.show && fieldsToShow.show();

      if (currVal === "" || currVal === "One Payment") {
        // When no selection has been made or current selection is "One Payment", remove values from All 3 dependent fields
        paymentCountField.val("");
        paymentFrequencyField.val("");
        givingYearsField.val("");
      } else if (currVal === "Irregular") {
        // When current selection is "Irregular", remove values from "Payment Frequency" and "Giving Years" fields
        paymentFrequencyField.val("");
        givingYearsField.val("");
      } else if (currVal === "Total") {
        // When current selection is "Total", remove values from "Payment Count" and "Giving Years" fields
        paymentCountField.val("");
        givingYearsField.val("");
      } else {
        // Default case - When current selection is anything else remove values from "Payment Count" and "Payment Frequency" fields
        paymentCountField.val("");
        paymentFrequencyField.val("");
      }
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
    { label: "Batch #",
      name: "batchSequence",
      width: 13,
      sortable: false,
      sorttype: "integer",
      classes: "batch-seq-cell" },

    { label: "Split #",
      name: "objOppty.Split_Sequence__c",
      width: 13,
      sortable: false,
      sorttype: "integer" },

    { label: "Account #",
      name: "objOppty.Account_Number_BGE__c",
      width: 25,
      sortable: false },

    { label: "Account Name",
      name: "accountName",
      width: 37,
      formatter: function (cellValue, options, rowObject) {
        return formatLinkCell(cellValue, rowObject.objOppty.AccountId);
      },
      sortable: false },

    { label: "Giving Name",
      name: "objOppty.Name",
      width: 45,
      formatter: function (cellValue, options, rowObject) {
        return formatLinkCell(cellValue, rowObject.objOppty.Id);
      },
      // align: "right",
      sortable: false },

    { label: "Giving Type",
      name: "selectedRT",
      width: 20,
      // align: "right",
      sortable: false,
      summaryType:'count',
      summaryTpl:'<b>{0} Items</b>' },

    { label: "Amount",
      name: "amount",
      width: 20,
      formatter: 'currency',
      formatoptions: {
        decimalSeparator:".",
        thousandsSeparator: ",",
        decimalPlaces: 2,
        prefix: "$"
      },
      summaryType:'sum',
      summaryTpl:'<b>{0} Total</b>',
      // align: "right",
      sortable: false },

    { label: "Source Code",
      name: "objOppty.rC_Giving__Source_Code__c",
      width: 25,
      // align: "right",
      sortable: false },

    { label: "Sharing Code",
      name: "sharingCode",
      width: 25,
      // align: "right",
      sortable: false },

    { label: "Sharing Entity",
      name: "sharingEntity",
      width: 25,
      // align: "right",
      sortable: false },

    { label: "Affiliation",
      name: "affiliation",
      width: 20,
      // align: "right",
      sortable: false },
	  
	{ label: "Recognition Credits",
      name: "objOppty.Total_Credits__c",
      width: 25,
       align: "right",
      sortable: false },

    { label: "Gift Mem?",
      name: "objOppty.Has_Soft_Credits__c",
      width: 20,
      formatter: function (cellValue, options, rowObject) {
        var imgName = "checkbox_checked.gif";
        if (cellValue === undefined || cellValue === null || !cellValue || cellValue === "false") {
          imgName = "checkbox_unchecked.gif";
        } else {
          if (rowObject && !rowObject.hasMatchingSoftCredit) {
           return '<img src="/img/msg_icons/error16.png" style="margin-left: 4px;" height="16" width="16" title="Total Amount of Soft Credit(s) does not match with Hard Credit Amount.">';
          }
        }
       return '<img src="/img/' + imgName + '" class="checkImg" height="16" width="21">';
      },
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

  var onSubGridExpansion = function(subgrid_id, row_id) {
    // Move the detail block to the row that is being expanded
    jQuery("#" + subgrid_id).append( jQuery(".bldp-custom-oppt-block") );
    // Set the subgrid table cell to consume 100% avaialble width
    jQuery("#" + subgrid_id).closest("td").attr("colspan", "100%");
  }

  var onGridLoad = function() {
    console.log("Grid Loaded...");
    if(_bgeApex.isAdjustBatch){
        console.log('Adjustbatch');
        for (i = 1; i <= _bgeApex.opportunityList.length; i++) {
        var currRow = jQuery("#" + gridIdPrefix + i);
        if (currRow && !_bgeApex.opportunityList[i-1].isAdjustementsCreated) {
          currRow.addClass("bge-adjusted-row");
        }
      }
    }else{
        var i, groups = jQuery(this).jqGrid("getGridParam", "groupingView").groups,
          l = groups.length,
          idSelectorPrefix = "#" + this.id + "ghead_0_";
        for (i = 0; i < l; i++) {
          var rowCount = groups[i].cnt,
            startRowNum = groups[i].startRow + 1;
          if (rowCount === 1) {
            // hide the grouping row
            jQuery(idSelectorPrefix + i).hide();
          } else {
            jQuery(idSelectorPrefix + i).children("td.batch-seq-cell").hide();
            for (j = 0; j < rowCount; j++, startRowNum++) {
              var currRow = jQuery("#" + gridIdPrefix + startRowNum);
              if (currRow) {
                currRow.addClass("bge-split-row");
                currRow.children('td.batch-seq-cell').html("");
              }
            }
          }
        }
    }
  }

  var autoResizeGridWithWindow = function() {
    // Auto-resize the grid when window width changes
    jQuery(window).bind('resize', function() {
      grid.setGridWidth(jQuery(window).width() - 70);
    }).trigger('resize');
  }

  var setCustomInterval = function (func, wait, times) {
    var c = true;
    var interv = function(w, t){
      return function(){
        if((typeof t === "undefined" || t-- > 0) && c) {
          setTimeout(interv, w);
          try{
            func.call(null);
          }
          catch(e){
            t = 0;
            throw e.toString();
          }
        }
      };
    }(wait, times);
    setTimeout(interv, wait);
    return {
      clear: function() {
        c = false;
      }
    };
  }

  var clearCustomInterval = function () {
    console.log("Calling clearCustomInterval");
    if (intervalHandle) {
      intervalHandle.clear();
      console.log("clearCustomInterval success");
    }
  }

  var toggleRowSaveButton = function () {
    console.log("toggleRowSaveButton");
    var isFormChanged = _bge.isUnsavedRow();
    if (isFormChanged) {
      _bge.clearCustomInterval();
      jQuery(".rowSave").prop("disabled", false).removeClass("btnDisabled").addClass("btn");
    } else {
      jQuery(".rowSave").attr("disabled", true).addClass("btnDisabled").removeClass("btn");
    }
  }
  
  var sortField = (_bgeApex.isAdjustBatch)?'batchSequence':'objOppty.Split_Sequence__c';

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
      sortname: sortField,
      grouping: ! _bgeApex.isAdjustBatch ,
      groupingView: {
        groupField: ['batchSequence'],
        groupSummary: [true],
        groupColumnShow : [true],
        groupSummaryPos: ['header'],
        showSummaryOnHide: true,
        groupText : ['<b>{0}</b>'],
        groupCollapse : false,
        groupOrder: ['asc']
      },
      loadComplete: onGridLoad
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
    isEditBeforeCancel: false,
    exapandLastFlag: false,
    reloadGrid: reloadGrid,
    showOpptDetail: showOpptDetail,
    cancelChange: cancelChange,
    saveOppt: saveOppt,
    addRow: addRow,
    exportItems: exportItems,
    saveBatch: saveBatch,
    editBatch: editBatch,
    cancelBatch: cancelBatch,
    releaseBatch: releaseBatch,
    addSplit: addSplit,
    afterAddRow: afterAddRow,
    afterSplitRow: afterSplitRow,
    afterSaveRow: afterSaveRow,
    afterCreateOpptyProd: afterCreateOpptyProd,
    afterRefreshList: afterRefreshList,
    toggleBackdrop: toggleBackdrop,
    collapseSections: collapseSections,
    chooseGivingFrequency: chooseGivingFrequency,
    isUnsavedRow: isUnsavedRow,
    focusOnGivingAmount: focusOnGivingAmount,
    focusOnSourceCode: focusOnSourceCode,
    openSoftCredit: openSoftCredit,
    setCustomInterval: setCustomInterval,
    clearCustomInterval: clearCustomInterval,
    toggleRowSaveButton: toggleRowSaveButton
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

function selectAllCheckboxes(obj, receivedInputID) {
  var inputCheckBox = j$('.checkboxClass');
  for (var i = 0; i < inputCheckBox.length; i++) {
    if (inputCheckBox[i].id.indexOf(receivedInputID) != -1 && !inputCheckBox[i].disabled) {
      inputCheckBox[i].checked = obj.checked;
    }
  }
}

$(document).ready(function() {
  j$("div[id*='pg:frm:OpptyWrapperList:j_id']").first().css('width', '120px');
  j$(".ihoImoPopup").addClass('hidePanel');
});

function updatePaymentURL(accId) {
  j$("#modalDiv").dialog('option', 'title', 'Testing').dialog('open');
}

function openIHOPopup() {
  FillAckLookup();
  FillRecipientAckCode();
  j$(".ihoImoPopup").removeClass('hidePanel');
}

function closeIHOPopup(closePopup) {
  j$(".ihoImoPopup").removeClass('hidePanel');
  if (closePopup == 'true') {
    j$(".ihoImoPopup").addClass('hidePanel');
  }
}

function openAdjustGivingPopup() {
  j$(j$("[id*=tableScrollTest]")[0]).css("overflow", "auto");
  j$(".adjustGivingPopup").removeClass('hidePanel');
}

function closeAdjustGivingPopup() {
    j$(".adjustGivingPopup").addClass('hidePanel');
}
function refreshListonError() {
    refreshList();
}
function openBatchPrefPopup() {
  j$(".batchPrefPopup").removeClass('hidePanel');
}

function closeBatchPrefPopup() {
  j$(".batchPrefPopup").addClass('hidePanel');
}

//Custom LookUp Page JS Code starts
var newWin = null;
function openLookupPopup(name, id, page, accId, oppId, accType, sourcCode, programType) {
  console.log('page', page);
  if (page == 'Campaign') {
    var url = "/apex/Campaign_Lookup_Page?namefield=" + name + "&idfield=" + id + "&deposit=" + _bgeApex.depositSite + "&cmpSouc=" + sourcCode + "&progTyp=" + programType;
    console.log('accId', accId == '');
    console.log('oppId', oppId == '');
    if (accId == 'AccID' && oppId == 'oppID') {
      newWin = window.open(url, 'Popup', 'height=500,width=600,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
      if (window.focus) {
        newWin.focus();
      }
    } else if (accId != '' && oppId != '' && accId.startsWith("001") && oppId.startsWith("006")) {
      var url = url + "&accId=" + accId + "&oppId=" + oppId;
      newWin = window.open(url, 'Popup', 'height=500,width=600,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
      if (window.focus) {
        newWin.focus();
      }
    } else if (accId != '' && accId.startsWith("001")) {
      var url = url + "&accId=" + accId;
      newWin = window.open(url, 'Popup', 'height=500,width=600,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
      if (window.focus) {
        newWin.focus();
      }
    } else {
      alert('Please Select Account');
    }
  } else if (page == 'Account') {
    openAccountLookup(name, id, false, accType);
  }
  //return false;
}
var selOppAdjust = false;
var selRecType = '';

function closeAccLookupPopup(callImoFunction) {
  if (null != newWin) {
    selOppAdjust = false;
    selRecType = '';
    newWin.close();
    /*if(callImoFunction != 'true'){
        refreshTble();
    }*/
  }
}

function closeLookupPopup() {
  if (null != newWin) {
    newWin.close();
    refreshTble();
  }
}

var isBatchItem = false;
function passComponentIds(row, campaignOrder, accOrder, oppId, isNew, existingAccId) {
  var targetId = vfId('camptargetId');
  var campaignSourCdeId = vfId('cmpSourceCode');
  var programType = vfId('programType');
  var targeName = vfId('targetName');
  var acctargetId = vfId('acctargetId');
  var acctargeName = vfId('acctargetName');
  var accId;
  console.log('isNew', isNew);
  console.log('existingAccId', existingAccId);
  console.log('existingAccIdEmpty', existingAccId == '');
  campaignRow = row;
  isBatchItem = true;
  if (isNew == 'true' && (existingAccId == null || existingAccId == '')) {
    var accEle = document.getElementById(acctargetId);
    accId = accEle.value;
    console.log('IdFound');
  } else {
    accId = existingAccId;
  }
  console.log('accId', accId);
  console.log('targeName', targeName);
  console.log('targetId', targetId);
  openLookupPopup(targeName, targetId, 'Campaign', accId, oppId, '', campaignSourCdeId, programType);
  //return false;
}
var isPledgeRecType;
// account Lookup
function passaccComponentIds(accOrder, recordType, isAdjust) {
  var acctargetId = vfId('acctargetId');
  var acctargeName = vfId('acctargetName');
  var acctType = vfId('acctType');
  selOppAdjust = isAdjust;
  selRecType = recordType;
  isPledgeRecType = recordType == 'Pledge'? true:false;
  openLookupPopup(acctargeName, acctargetId, 'Account', '', '', acctType, '', '');
  //return false;
}
//Imo account Lookup
function imopassaccComponentIds() {
  var name = vfId('ImoacctargetName');
  var id = vfId('ImoacctargetId');
  var accType = vfId('ImoacctargetType');
  openAccountLookup(name, id, true, accType);
  //return false;
}

function openAccountLookup(name, id, forImo, accType) {
  var url = "/apex/Account_Lookup_Page?namefield=" + name + "&idfield=" + id + "&imo=" + forImo + "&accType=" + accType+"&isPledge="+isPledgeRecType;
  newWin = window.open(url, 'Popup', 'height=650,width=1000,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
  if (window.focus) {
    newWin.focus();
  }
  return false;
}

// Source Code Remoting Function
function sourceCodeChanged(row, campaignOrder) {
  var sorucetargetId = vfId('camptargetId');
  var sourcetargeName = vfId('targetName');
  var sourcCodeTargetId = vfId('sourceCode');
  var campaignSourCdeId = vfId('cmpSourceCode');
  var programType = vfId('programType');
  var sourceCodeEle = document.getElementById(sourcCodeTargetId);
  console.log('sourCeCode:' + sourceCodeEle.value);

  _bge.toggleBackdrop('show');
  Visualforce.remoting.Manager.invokeAction(
    _bgeRemoteAction.populateCampaignLookup,
    row, sourceCodeEle.value, _bgeApex.depositSite,
    function(result, event) {
      _bge.toggleBackdrop('hide');
      if (event.status) {
        if (result[0] != 'FaLsE') {
          console.log('RemotingResponse', result[0]);
          document.getElementById(sourcetargeName).value = unescape(result[2]);
          document.getElementById(sorucetargetId).value = result[1];
          refreshTble();
        } else if (result[0] == 'FaLsE') {
          console.log('RemotingResponse', result);
          alert('Multiple Campaigns or no Campaign was found. Please select the correct Campaign.');
        }
      } else if (event.type === 'exception') {
        console.log('Exception');
      } else {
        console.log('Exception');
      }
    }, { escape: false, timeout: 30000 }
  );
}


// Remoting Function
function accountNumberChanged(row, accOrder, isNew) {
  var acctargetId = vfId('acctargetId');
  var acctargeName = vfId('acctargetName');
  var accNumberTargetId = vfId('accountNumber');
  var accNumberEle = document.getElementById(accNumberTargetId);
  console.log('isNew', isNew);

  var accId;
  if (isNew == 'true') {
    accId = accNumberEle.value;

    console.log('accId>>', accId);
    _bge.toggleBackdrop('show');
    Visualforce.remoting.Manager.invokeAction(
      _bgeRemoteAction.populateAccountLookup,
      row, accNumberEle.value,
      function(result, event) {
        _bge.toggleBackdrop('hide');
        if (event.status) {
          if (result[0] != 'FaLsE') {
            console.log('RemotingResponse::', unescape(result[2]));
            console.log('RemotingResponse::Orgi:::', result[2]);
            document.getElementById(acctargeName).value = unescape(result[2]);
            document.getElementById(acctargetId).value = result[1];
            refreshTable(result[1], row);
          } else if (result[0] == 'FaLsE') {
            alert('Multiple accounts or no accounts found Please Select AccountId');
          }
        } else if (event.type === 'exception') {
          console.log('Exception');
        } else {
          console.log('Exception');
        }
      }, { escape: false, timeout: 30000 }
    );
  }
}

function refreshTable(accId, row) {
  renderTable(accId, row);
  //refreshTble();
}

function openPledgesIconShowHide(hasOpenPledges) {
  var openPledgesButton = vfElement('openPledges');

  if (hasOpenPledges == "true" && selOppAdjust) {
    setOpenPledgeIcon();
    openPledgesButton.show();
  } else {
    openPledgesButton.hide();
  }
}

//Custom LookUp Page JS Code Ends
//Demo Popup Modal
function showHidePaymentMethod(paymentMethod, row, accountIdOrder, isNew, existingaccId) {
  console.log('ModalEntered', paymentMethod.value);
  var accTarget = vfId('acctargetId');
  var paymentMTy =  paymentMethod.value;
  if(paymentMTy == 'EFT' || paymentMTy == 'Charge Card' || paymentMTy == 'Paypal'
  || paymentMTy == 'Voucher' || paymentMTy == 'Securities' || paymentMTy == 'Charge Card (No Charge)'){
      document.getElementById(vfId('psReqBlock')).style.visibility = 'hidden';
  }else{
      document.getElementById(vfId('psReqBlock')).style.visibility = 'visible';
  }
  var accId;
  if (isNew == 'true' && (existingaccId == null || existingaccId == '')) {
    var accEle = document.getElementById(accTarget);
    accId = accEle.value;
  } else {
    accId = existingaccId;
  }
  // check for the value not null and blank.
  if (accId != '' && accId != '000000000000000') {
    console.log('accId', accId.value == '000000000000000');
    console.log('accId', accId.value);
    console.log('row', row);
    togglePaymentMethodModal(row, paymentMethod.value, accId);
  } else if (accId == '' || accId == '000000000000000') {
    alert('Please Select the Account');
  }
}

function close() {
  console.log('Close');
  $("#tstpopup").removeClass('hidePanel');
}
//Demo Popup Modal Ends

var j$ = jQuery.noConflict();
j$(function() {
  /*Insert the jQuery style sheets in the Head.*/
  /*Insert the Modal dialog along with the VF as an iframe inside the div.*/
  j$("head").after(
    j$("<link>", {
      rel: "stylesheet",
      href: "https://code.jquery.com/ui/1.10.4/themes/smoothness/jquery-ui.css"
    }));
  j$("body").after(
    j$("<div>", {
      id: "modalDiv",
      style: "display:none;"
    }).append(
      j$("<iframe>", {
        id: "vfFrame",
        src: "",
        height: 450,
        width: 940,
        frameBorder: 0
      })
    ));
  /*Initialize the Dialog window.*/
  j$("#modalDiv").dialog({
    autoOpen: false,
    height: 470,
    width: 970,
    modal: true,
  });
});

// Open Grants
function openGrants(row, accId, amount, batchId, payment, recordType, isSFT) {
  var isPledge = (recordType == 'Pledge' ? true : false);

  if (accId == null || accId == '') {
    accId = document.getElementById(vfId('acctargetId')).value;
  }

  console.log("accId>>",accId);
  amount = document.getElementsByClassName('rC_Giving__Giving_Amount__c')[0].value;
  payment = document.getElementsByClassName('rC_Giving__Payment_Method__c')[0].value;
  var paymentSub = document.getElementsByClassName('Payment_Subtype__c')[0].value;
  console.log("amount>>",amount);
  console.log("payment>>",payment);
  console.log("paymentSub>>",paymentSub);
  if(payment == '' || (payment == 'Cash/Check' && paymentSub == '')) {
      alert('Please select a Payment Method prior to attaching to a pledge');
  }else {
      var url = "/apex/BatchItem_Pledges_Proposal_Grants?accId=" + accId + "&row=" + row + "&bamount=" + amount + "&batchId=" + batchId + "&Payment=" + payment + "&PP=" + isPledge + "&isSC=" + isSFT;
      newWin = window.open(url, 'Popup', 'height=500,width=1000,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
      if (window.focus) {
        newWin.focus();
      }
  }
}

// updateParentOpp
function updateParentOpp(oppId, row, ispledge, openfromSft) {
  _bge.isSave = true;
  modifyrow(row, oppId, ispledge, openfromSft);
}

//deleteRow
function deleteRow(rowIndex, gLcheckBox) {
  if (gLcheckBox == 'true') {
    alert('You cannot delete a Giving Record that has posted to the GL');
  } else if (gLcheckBox == 'false') {
    var r = confirm("This will delete this Giving record. Are you sure you want to proceed?");
    if (r == true) {
      deleteOppRow(rowIndex);
    } else {
      txt = "You pressed Cancel!";
    }
  }

}

//Refresh BatchItemRow
var campaignRow;

function batchItemTableRefresh() {
  var batchId = _bgeApex.batchLogId;
  console.log('batchId', batchId);
  if (batchId = null) {
    populateFundFields(campaignRow);
  }
}

//populate recordTypeValue
function populateRecordTypeField(row, recordColOrder) {
  var recordType = vfElement("recordType");
  var ispledgePayment;
  if (recordType != null) {
    if (recordType.val() == 'Pledge Payment') {
      ispledgePayment = true;
    } else {
      ispledgePayment = false;
    }
  }
  console.log('Onchange', recordType.val());
  populateRecordTypeaction(row, ispledgePayment);
}

//CmpProductsIds
function cmProdIds(idsStr) {
  console.log('hello', idsStr);
  console.log('row', campaignRow);
  if (isBatchItem == true) {
    setproductIds(idsStr, campaignRow);
  }
  isBatchItem = false;
}

function submitListener(e) {
  var keynum = 0;
  if (window.event) {
    keynum = window.event.keyCode;
  } else if (e.which) {
    keynum = e.which;
  }

  // Here we check whether the Enter button was pressed
  if (keynum == 13) {
    console.log('Entered');
  }
}

function OpenEnterKeyErrorPopup() {
  j$('enterKeyRestrictMsgPopup').removeClass('hidePanel')
}

//Manage Pledge Opportunity
function managePledgeUrl(oppId){
  var url = 'rc_giving__opportunity_manage?currentTab=transactions&id='+oppId+'&retURL='+oppId+'&isdtp=vw';
  newWin5 = window.open(url, 'managePledgeWindow', 'height=500,width=1000,left=100,top=100,resizable=no,scrollbars=no,toolbar=no,status=no');
  if (window.focus) {
    newWin5.focus();
  }
}

function alertUseronSoftCredits(hasSoftCredits){
    if(hasSoftCredits == 'true'){
        alert('This transaction has a soft credit. Click the \'Soft Credit\' button and adjust soft credit total to match the gift total');
    }
    callAdjustmentOppty();
}

function callAdjustmentOppty(){
    _bge.isSave= true;
    saveAdjustmentOppty();
}

function ConfirmsaveAdjustmentOppty(hasSoftCredits){
  var r = confirm("This will commit the adjustment. Are you sure you want to proceed?");
  if(r){
    alertUseronSoftCredits(hasSoftCredits);
  }
  return null;
}

function ConfirmcancelAdjustment(){
  var r = confirm("This will permanently cancel the adjustment. Are you sure you want to proceed?");
  if(r){
    cancelAdjustment();
  }
  return null;
}

//SoftCreditTableOpen
function OpenSoftCreditGrid(OppId, batchId, isReleased) {
  console.log('OppId', OppId);
  console.log('batchId', batchId);
  var url = 'apex/SoftCreditPage?parentOppId=' + OppId + '&batchLogId=' + batchId +'&isReleased='+isReleased;

  var scrWidth, scrHeight;
  if (screen.availHeight) {
    scrHeight = screen.availHeight;
    scrWidth = screen.availWidth;
  } else {
    scrHeight = screen.height - 50;
    scrWidth = screen.width - 50;
  }

  var windowParams = 'height='+ scrHeight +',width=' + scrWidth + ',left=0,top=0,resizable=no,scrollbars=no,toolbar=no,status=no';
  newWin1 = window.open(url, 'scwindowtitle', windowParams);
  newWin1.resizeTo(scrWidth, scrHeight);
  if (window.focus) {
    newWin1.focus();
  }
}

function closeSoftCreditPopup() {
  if (null != newWin1) {
    newWin1.close();
  }
}

function refreshList(exapandLast) {
  if (exapandLast !== false) {
    exapandLast = true;
  }
  _bge.exapandLastFlag = exapandLast;
  refreshOpptyList();
}
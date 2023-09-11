import {
    LightningElement,
    api,
    track,
    wire
} from 'lwc';
import getAllFields from '@salesforce/apex/Innova_DataGeneratorCls.getAllFields';
import getAllObject from '@salesforce/apex/Innova_DataGeneratorCls.getAllObject';
import getAllUsers from '@salesforce/apex/Innova_DataGeneratorCls.getAllUsers';
import wrapfastCreateRecordsUser from '@salesforce/apex/Innova_DataGeneratorCls.wrapfastCreateRecordsUser';
import checkSync from '@salesforce/apex/Innova_DataGeneratorCls.checkSync';
import getDataFromExternalOrg from '@salesforce/apex/Innova_DataGeneratorCls.getDataFromExternalOrg';
import pushDataToExternalOrg from '@salesforce/apex/Innova_DataGeneratorCls.pushDataToExternalOrg';
import viewCreatedRecords from '@salesforce/apex/Innova_DataGeneratorCls.viewCreatedRecords';
//import viewMDT from '@salesforce/apex/Innova_DataGeneratorCls.viewMDT'
import deactivateValidationRulesForSobject from '@salesforce/apex/Innova_DataGeneratorCls.deactivateValidationRulesForSobject';
//import insertRec from '@salesforce/apex/ToolingAPIHelper.insertRec';
import showValidationRule from '@salesforce/apex/Innova_ToolingAPIHelper.queryValidationRule';
import fetchRelatedSObjects from '@salesforce/apex/Innova_DataGeneratorCls.fetchRelatedSObjects';
import loadCSVData from '@salesforce/apex/Innova_DataGeneratorCls.loadCSVData';

//import viiewActivityRecord from '@salesforce/apex/Innova_DataGeneratorCls.vioewActivityRecord';

import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    NavigationMixin
} from "lightning/navigation";

import {
    loadScript
} from 'lightning/platformResourceLoader';


import LightningModal from 'lightning/modal';



export default class Innova_DataGeneratorComponent extends NavigationMixin(LightningElement) {

   
    ready = false;

    @wire(getAllObject)
    allObjects({
        error,
        data
    }) {
        if (data) {
            this.objOptions = JSON.parse(JSON.stringify(data['allObject']));
            console.log('objoptions  ', this.objOptions);
        } else if (error) {
            console.log('error   ', error);
        }
    }
    objectName;
    objOptions;
    @track allFieldsFromObject;
    isNextEnabled = true;
    hideOverlay = false;
    isFieldDisabled =false;
    //for pagination
    repeatChild = [];
    visibleRepeatChild;
    parentRecordSize = 0;

    isCreateMultiple = false;
    isFastCreate = false;
    relatedRecPopup = false;
    isObjectBlank = true;
    isPushFileInput = false;
    fileData;
    totalTime;
    activeTabValue = 'Single';
    btnLabel = 'Sync';
    disablePull = true;
    disableSync = true;

    numValue = "5";
    @track exportedvalidations = {};

    isViewUploaded = false;
    numberFieldValue = "1";
    @track multiplerecords = false;
    cautionvar = 'Caution : Before creating the data, please make sure the system/custom validations are disabled or bypassed in the system.' + '\n' + 'We advise to refer the validation rule set below.';


    isCreateRelated = false;
    isCreateForSpecificUser = false;
    isCreateDisabled = false;
    userList;
    selectedUserId;
    relatedSObjRecords;
    selectedRelatedObjName;
    buttonDisabled = false;
    @track
    viewMDTrecord;
    namedCredential;
    squery;
    csvData;
    toggleIconName;
    soqlQuery;
    insertError;
    insertCSV;
    selectedObject;
    pullObjectName;
    @track otherOrgObjects;
    @track activityDetails={};
    finalParentCol;
    finalChildCol;
    finalParentData = '';
    finalChildData = ''
    relatedChildObjects;
    jsonData;

    //  = [{objName:'Account',isMaster:true},{objName:'Contact',isMaster:false},
    //                             {objName:'Opportunity',isMaster:false},{objName:'Lead',isMaster:false}];

    columnHeader = ['Validation Name', 'Validation Link'];
    get options() {
        return [{
                label: '5',
                value: '5'
            },
            {
                label: '10',
                value: '10'
            },
            {
                label: '15',
                value: '15'
            },
            {
                label: '20',
                value: '20'
            },
            {
                label: '25',
                value: '25'
            },
            {
                label: '30',
                value: '30'
            },
        ];
    }

    get relatedOptions() {
        return [{
                label: '1 child, 1 parent',
                value: 'single'
            },
            {
                label: '1 parent, multiple child',
                value: 'multiple'
            },
        ];
    }


    myRecordId;

    get acceptedFormats() {
        return ['.csv', 'png'];
    }

    get disablepullcsv(){
        return !this.csvData;
    }

    get disableInsercsv(){
        return !this.insertCSV;
    }

    handleUploadFinished(event) {
        let startTime = Date.now();
        // Get the list of uploaded files
        console.log('this.myRecordIdv ', this.myRecordId, ' this.objectName  ', this.objectName)
        const uploadedFiles = event.detail.files;
        console.log('uploadedFiles  ', uploadedFiles);

        loadCSVData({
            contentDocumentId: uploadedFiles[0].documentId,
            sObjName: this.objectName
        }).then(data => {
            let resList=data.resultList
            console.log('resList   ', resList);
            this.totalTime = (Date.now() - startTime) / 1000;
            if (resList && !resList.includes('Some of the records')) {
                this.showSuccessToast(JSON.stringify(resList), this.totalTime);
            }
            if (resList && resList.includes('Some of the records')) {
                this.showInfoToast(JSON.stringify(resList), this.totalTime);
            }
            if (resList && resList.includes('Records are not')) {
                this.showErrorToast(JSON.stringify(resList));
            }
            this.activityDetails=data;
        }).catch(error => {
            this.showErrorToast(error.body.message);
        })
        // alert('No. of files uploaded : ' + uploadedFiles.length);
    }
    // get objOptions(){
    //     return [
    //         { label: 'Lead', value: 'Lead' },
    //         { label: 'Account', value: 'Account'},

    //     ];
    // }


    connectedCallback() {
        this.repeatChild = [{
            no: 1
        }, {
            no: 2
        }, {
            no: 3
        }, {
            no: 4
        }, {
            no: 5
        }];
        this.parentRecordSize = 1;
        //this.getAllUsers();
        // viewCreatedRecords(); 
        this.ready = true
    }

    @track recordCols = [

        {
            label: "Name",
            type: "button",
            typeAttributes: {
                label: {
                    fieldName: "Name"
                },
                name: "gotoOpportunity",
                variant: "base"
            }
        },
        {
            label: "Created Date",
            fieldName: "CreatedDate"
        }
    ];
    //@track displayRecords=[{Id:'0065g00000OhbZyAAJ','Name':'Test Opportunity'},{Id:'0065g00000OhbZyAAJ','Name':'Dummy Opportunity'}];

    createRelated(event) {
        console.log('this.isCreateRelated   ', this.isCreateRelated);
        let value = event.target.checked;
        this.isCreateRelated = value;
        console.log('this.isCreateRelated   ', this.isCreateRelated, '  Selected OBJ  ', this.selectedRelatedObjName);

    }

    createRecForUser(event) {

        console.log('createRecForUser  ', event.target.checked);
        this.isCreateForSpecificUser = event.target.checked;
        if (this.isCreateForSpecificUser) {
            this.getAllUsers(this.objectName);
        }
    }

    handleSingleRecInsEvent(event) {
        const eventDetail = event.detail;
        let insIds= eventDetail.result.insertedRecIds;
        this.activityDetails=eventDetail.result;
        console.log('event  ', event.detail, '  handleSingleRecInsEvent insIds ', insIds);
        console.log('eventDetail STR  ', eventDetail , '  stringify  ', JSON.stringify(eventDetail));
       // this.isNextEnabled = !textVal;
       // this.handlefromParent();

    }
    handlefromParent() {
        this.template.querySelector('c-innova_-pagination-component').callFromParent();
    }

    insertSeqRecords() {
        console.log('insertSeqRecords  ');
        this.relatedRecPopup = true;
    }

    relatedRecord() {
        console.log('relatedrec   ');
        this.template.querySelector('c-innova_-data-sample-component').relatedrec(this.selectedUserId);
    }
    handleNumberChange(event) {
        this.numberFieldValue = event.target.value;
    }

    isMultipleChild = false;
    handleRelChange(event) {
        this.isMultipleChild = event.detail.value;
        console.log('isMultipleChild   ', this.isMultipleChild);
        if (this.isMultipleChild == 'multiple') {
            this.multiplerecords = true;
        } else {
            this.multiplerecords = false;
            this.numberFieldValue = '1';
        }
    }

    customHiderelatedRecPopup() {

        this.relatedRecPopup = false;
    }

    noOfRecordtoCreate(event) {
        let noOfrec = event.target.value;
        if (noOfrec && noOfrec > 0) {
            this.repeatChild = [];
            let tempJson = {};

            for (var i = 1; i <= noOfrec; i++) {
                tempJson.no = i;
                this.repeatChild.push(tempJson);
                tempJson = {};
            }
            console.log(noOfrec, ' noOfRecordtoCreate this.repeatChild  ', this.repeatChild);
        }
    }




   
    wrapfastCreateRecordsUser() {
        console.log('fastCreateRecords commented');
       
        let startTime = Date.now();
        var noOfRecordFastCreate = '';
        if (this.template.querySelector(".noOfRecordFastCreateTab")) {
            noOfRecordFastCreate = this.template.querySelector(".noOfRecordFastCreateTab");
        }
        if (noOfRecordFastCreate == null || noOfRecordFastCreate == '') {
            this.showErrorToast('Please provide No of records to create');
            return;
        }
        console.log('noOfRecordFastCreate ', noOfRecordFastCreate.value, ' this.objectName ', this.objectName);
        
        let wrapperInputJSON = { objName: this.objectName, count: noOfRecordFastCreate.value , modeOfCreation: this.activeTabValue, recUserId: this.selectedUserId };
        wrapfastCreateRecordsUser({ ivw: JSON.stringify(wrapperInputJSON) }).then(data => {
            //JSON.stringify
            this.totalTime = (Date.now() - startTime) / 1000;
            console.log('fastCreateRecords  stringify ' + JSON.stringify(data));
            
           // console.log('indexx   ' + (JSON.stringify(data)).indexOf('EXCEPTION'));
            this.activityDetails = JSON.parse(JSON.stringify(data));
            console.log(' revaa wrapfastCreateRecordsUser activityDetails = '+this.activityDetails );
            if (this.activityDetails.errorRecordsCount > 0) {
                this.showErrorToast(JSON.stringify(data));
            } else {
                this.showSuccessToast(' ', this.totalTime);
            }
           

        }).catch(e => {
            console.log('Error fastCreateRecords ' + JSON.stringify(e));
            this.showErrorToast(e);
        })
        
    }

    //fetch list of objects
    handleChangeObjectName(event) {
        // console.log('handleObjectNameChange')
        // this.objectName=event.detail.value;
        this.objectName = event.target.value;
        console.log('handleObjectNameChange  ' + this.objectName)
        if (this.objectName && this.objectName != 'None') this.isObjectBlank = false;
        this.fetchFieldPicklist(this.objectName);
        this.fetchRelatedObjects(this.objectName);

    }
    async fetchFieldPicklist(objname) {
        console.log('objname', objname);
        if (this.objectName == 'None') return;
        getAllFields({
                'objectName': objname
            })
            .then((result) => {
                if (result) {
                    //var data=result['AllFields'];
                    var data = result['AllFields'].map((item) => ({
                        ...item,
                        isSelected: false
                    }));
                    console.log('data  getAllFields ', data);

                    this.allFieldsFromObject = data;
                    this.allFieldsFromObject.map((val, index) => {
                        val.isPicklist = false;
                        val.isDateType = false;
                        if (val.dataType == 'PICKLIST' && val.picklistValues.length != 0) {
                            val.isPicklist = true;
                            let pickJSONArr = [];
                            let pickJSON = {};
                            for (let i = 0; i < val.picklistValues.length; i++) {
                                pickJSON.pickKeys = val.picklistValues[i];

                                pickJSONArr.push(pickJSON);
                                pickJSON = {};

                            }
                            val.pickJSONArrRes = pickJSONArr;
                            console.log(' val.pickJSONArrRes   ', val.pickJSONArrRes);


                        } else if (val.dataType == 'DATE') {
                            val.isDateType = true;
                        }
                        // else if(val.dataType !='PICKLIST'){
                        //     val.isPicklist=false;
                        // }
                        return val;
                    })

                    console.log('data  getAllFields allFieldsFromObject After ', this.allFieldsFromObject);


                }
            })
    } catch (error) {
        console.log(error);

    }

    customCss = 'classNone';
    isColorfull = false;

    fetchRelatedObjects(objName) {
        console.log('objName result ', objName);

        fetchRelatedSObjects({
            sObjName: objName
        }).then(result => {
            //JSON.parse(result.data).records;
            console.log('fetchRelatedSObjects result ', result);
            console.log('JSON.parse(result.data).records;   ', JSON.parse(result).RelatedObj);
            this.relatedSObjRecords = JSON.parse(result).RelatedObj.map((val, index) => {
                let isMasterBool = val.isMaster;
                val.objId = (index + 1).toString();
                // if(index == 1){
                // val.objName='Contact';
                //}
                if (isMasterBool)
                    val.customCss = 'classMaster ';
                else
                    val.customCss = 'classNone ';
                // val.stylecolor=isMasterBool ? "classMaster relObj" :"classNone relObj";
                return val;
            });
            console.log('this.relatedSObjRecords   ', this.relatedSObjRecords);

        }).catch(error => {
            console.log('fetchRelatedSObjects error ', error);

        })
    }


    addColor(event) {
        console.log('addColor');
        //  this.template.querySelector('.box').classList.remove('highlight');

        // event.target.classList.remove('highlight');

        // event.target.classList.add('highlight');

    }
    // get divBackground() {
    //     return this.isColorfull ? "slds-card backgroundColor" : "slds-card backgroundNoColor";
    //  }

    //  handleClick(){
    //    this.isColorfull = !this.isColorfull; 
    //  }


    handleChangeNumber(event) {
        this.numValue = event.detail.value;
    }



    showErrorToast(e) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: e,
            variant: 'error',
            mode: 'dismissible'
        })
        this.dispatchEvent(evt);
    }
    showWarningToast(e) {
        const evt = new ShowToastEvent({
            title: '',
            message: e,
            variant: 'info',
            mode: 'dismissible'
        })
        this.dispatchEvent(evt);
    }

    showSuccessToastOne(e) {

        const evt = new ShowToastEvent({
            title: `Success`,
            message: e,
            variant: 'success'
        })
        this.dispatchEvent(evt);
    }

    showSuccessToast(e, timeTaken) {

        const evt = new ShowToastEvent({
            title: `Success!  Time Taken : ${timeTaken} s`,
            message: e,
            variant: 'success',
            mode: 'dismissible'
        })
        this.dispatchEvent(evt);
    }

    showInfoToast(e, timeTaken) {
        const evt = new ShowToastEvent({
            title: timeTaken,
            message: e,
            variant: 'warning',
        });
        this.dispatchEvent(evt);
    }
    updatePaginationHandler(event) {
        this.visibleRepeatChild = [...event.detail.records]
        let currPage = event.detail.currentPage;
        let totalPage = event.detail.totalPage;
        if (currPage == totalPage) {
            this.closeModal();
        }

        console.log('currPage  ', currPage);
        console.log('totalPage  ', totalPage);
    }
    // **  open model to view interted record details  *//
    createMultiple(event) {
        let value = event.target.checked;
        console.log('createMultiple value  ', value);
        // to open modal set isCreateMultiple tarck value as true
        this.isCreateMultiple = event.target.checked;
    }

    fastCreateEnable(event) {
        let value = event.target.checked;
        this.isFastCreate = value;
        console.log('this.isFastCreate   ', this.isFastCreate);

    }
    closeModal() {
        // to close modal set isCreateMultiple tarck value as false
        this.isCreateMultiple = false;
    }


    // **  open model to view interted record details  *//
    openViewUploaded() {
        // to open modal set isModalOpen tarck value as true
        this.isViewUploaded = true;
    }
    closeViewUploaded() {
        // to close modal set isModalOpen tarck value as false
        this.isViewUploaded = false;
    }

    // navigate to inserted record page
    navigateRecordPage(event) {
        console.log('event.detail.row.Id   '+JSON.stringify(event.detail.row))
        if (event.detail.action.name === "gotoOpportunity") {
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    recordId: event.detail.row.Id,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }
        if (event.detail.action.name === "gotoActivity") {

            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    recordId: event.detail.row.actvityId,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }
    }
 

    exportValidationError(event) {
        console.log(event.detail.records)
        console.log(' here in export>>');
        showValidationRule({
            sObjectName: this.objectName
        }).then(result => {
            if (result) {
                console.log('validation rule>> ', result);
                console.log('437 result[0].length = ' + result);
                console.log('437 result[0] is NUll? ' + (result[0] == null));
                //console.log('438 result.length = '+result.length);
                if (result[0] == '' || result[0] == null) {
                    this.buttonDisabled = true;
                    this.showWarningToast("There are no active validation rules for " + this.objectName);
                } else {
                    this.exportedvalidations = result;
                    if (this.exportedvalidations) {
                        let doc = '<table style="width: 100%;border-collapse: collapse;">';

                        // Add all the Table Headers
                        doc += '<tr style = "text-align:left;font-size:11pt;color:#002060;font-weight: normal;font-family: Calibri;">';
                        this.columnHeader.forEach(element => {
                            doc += '<th>' + element + '</th>'
                        });
                        doc += '</tr>';
                        // Add the data rows
                        this.exportedvalidations.forEach(record => {
                            console.log('record ', record);
                            doc += '<tr>';
                            doc += '<td style = "font-size:11pt;text-align:right;white-space:nowrap;color:#002060">' + record.validationName + '</td>';
                            doc += '<td style = "font-size:11pt;text-align:right;white-space:nowrap;color:#002060">' + record.validationLink + '</td>';
                            //doc += '<th>'+record.FirstName+'</th>'; 
                            //doc += '<th>'+record.LastName+'</th>';
                            //doc += '<th>'+record.Email+'</th>'; 
                            doc += '</tr>';
                        });
                        doc += '</table>';
                        console.log('doc  ', )
                        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
                        let dowEle = document.createElement('a');
                        dowEle.href = element;
                        dowEle.target = '_self';
                        // use .csv as extension on below line if you want to export data as csv
                        dowEle.download = this.objectName + ' ' + 'Exported Validations.xls';
                        console.log('dowEle ' + dowEle);
                        document.body.appendChild(dowEle);
                        dowEle.click();
                    }
                }

            }

        }).catch(error => {
            console.log('validation export error  ', error);
            this.showErrorToast(error.body.message);

        })

    }


    // Logic to display related Sobject data START 

    handleSelect(event) {
        let obj = event.detail;
        obj = JSON.parse(obj);
        console.log('obj  selectedRelatedObjName ', obj);
        let objId = obj.objId;
        this.selectedRelatedObjName = obj.objName;
        this.selectedCase = this.relatedSObjRecords.find(c => c.objId === objId);
        console.log('selectedRelatedObjName  ', this.selectedRelatedObjName);
        this.toggleListItems('selected', objId);
    }


    //used to handle related object  
    handleMouseover(event) {

        console.log('FROM handleMouseover ', event.target.dataset.id);
        this.toggleListItems('mouseIsOver', event.target.dataset.id);
    }

    //used to handle related object
    handleMouseout(event) {
        event.target.mouseIsOver = false;
    }

    //used to handle related object
    toggleListItems(property, objId) {
        this.template.querySelectorAll('c-innova_-related-object-list-component').forEach(item => {
            console.log(item.relObj.objId, '  objId ', objId);
            if (item.relObj.objId === objId) {
                item[property] = true;
            } else {
                item[property] = false;
            }
        });
    }


    //   // Logic to display related Sobject data END


    insertRecords() {

        // if(this.selectedRelatedObjName && this.selectedRelatedObjName != null) {
        // this.relatedRecPopup=true;
        // return;
        // }
        console.log('this.activeTabValue  ', this.activeTabValue);
        if (this.activeTabValue === 'Single') {
            this.template.querySelector('c-innova_-data-sample-component').insertRecord(this.activeTabValue, this.selectedUserId);
            return;
        }
        if (this.activeTabValue === 'Related' && this.selectedRelatedObjName) {
            this.relatedRecPopup = true;
            return;
        }
        if (this.activeTabValue === 'Fast') {
            this.wrapfastCreateRecordsUser();
        }
    }

    //Get All users
    getAllUsers(objName) {
        console.log(' getAllUsers ');
        getAllUsers({
            objName: objName
        }).then(data => {
            this.userList = JSON.parse(data).userList;
            console.log(' getAllUsers userList ', this.userList);
        }).catch(error => {
            console.log('error getAllUsers ', error);
        });

    }

    get disableSubmit(){
        console.log(this.fileData && this.selectedObject);
        return !(this.fileData && this.selectedObject);
    }

    //Handle User Change
    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        console.log('selectedUserId  ', this.selectedUserId);
    }

    tabChanged(event) {
        this.isFieldDisabled=false;
        this.activeTabValue = event.target.value;
        this.isCreateDisabled = false;
        if (this.activeTabValue === 'Multiple') {
            this.isCreateDisabled = true;
        }
        if(this.activeTabValue === 'PushRecords' || this.activeTabValue ==='Push/Pull'){
            this.isFieldDisabled=true;
        }else{
            this.isFieldDisabled=false;
        }
  
        console.log('activeTabValue ', this.activeTabValue);
    }
    // PAGINATION LOGIC START
    // JS Properties 
    @track pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    @track totalRecords = 0; //Total no.of records
    @track pageSize; //No.of records to be displayed per page
    @track totalPages; //Total no.of pages
    @track pageNumber = 1; //Page number    
    @track recordsToDisplay = []; //Records to be displayed on the page


    get bDisableFirst() {
        return this.pageNumber == 1;
    }

    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }


    handleRecordsPerPage(event) {
        console.log('this.data.length =' + this.data.length);
        console.log('event.target.value =' + event.target.value);
        this.pageSize = event.target.value; //[];//this.data.length;//event.target.value;
        this.paginationHelper();
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }


    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = []; // this.displayRecords;
        // calculate total pages
        //this.records = this.displayRecords;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push((this.displayRecords[i]));
        }
    }
    // PAGINATION LOGIC END
    
    
    // innovaActivity.Total_records_count__c   = wrapper.totalRecordsCount;
    // innovaActivity.Success_records_count__c = wrapper.successrRecordsCount;
    // innovaActivity.Error_records_count__c   = wrapper.errorRecordsCount;
    // innovaActivity.Mode_of_Creation__c      = wrapper.modeOfCreation;
    // innovaActivity.Requested_By__c          = wrapper.requestedBy;
    
    
    viewCreatedRecords() {
        console.log('viewCreatedRecords sobjName = ' + this.objectName);
       //this.viewActivity();
       let ids;
       try{
        console.log('CHECK viewCreatedRecords this.activityDetails = ' , this.activityDetails);
        console.log('CHECK viewCreatedRecords this.successrRecordsCount = '+this.successrRecordsCount);
        console.log('CHECK viewCreatedRecords this.activityDetails.insertedRecIds = '+this.activityDetails.insertedRecIds);
        ids=(this.activityDetails.insertedRecIds).toString();
        console.log('CHECK ids  = '+ids);

        viewCreatedRecords({
            sObjName: this.objectName, recIds: ids
        }).then(
            data => {
                if (data != null) {
                    console.log('result data.length = ' + data.length);
                    console.log('called viiewActivity successfully  this.activityDetails : ', this.activityDetails);
                    
                    this.viewActivity();
                    this.totalRecords = data.length; // update total records count  
                    // console.log('this.activityDetails = '+this.activityDetails);
                    console.log('anu data of succss = '+JSON.stringify(data));
                    this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option
                    this.displayRecords = data;
                    this.paginationHelper(); // call helper menthod to update pagination logic 
                    this.isViewUploaded = true;
                   
                }
                return;
                
            }
        ).catch(e => {
            this.isViewUploaded = false;
            console.log('viewCreatedRecords errors: ' + JSON.stringify(e));
            console.log(e);
        });
    }catch(e){
console.log('error from View Upload '+e);
    }

        
    }
  @track  activityData=[];
    viewActivity(){
        let actData=[];
        actData.push( JSON.parse(JSON.stringify(this.activityDetails)));
         this.activityData =actData;
        console.log('reva this.ctivityData : ',this.activityData);
        console.log('reva this.activityDetails : ',this.activityDetails);
      
    }
    //employeeData = ;
    employeeData = [{
        objName: 'Account',
        modeOfCreation:'Fast Record Creation',
        totalRecordsCount :3,
        successrRecordsCount:3,
        errorRecordsCount:0
    }];
//     employeeColumns = [
//     {
//         label: 'Object',
//         fieldName: 'objName'
//     },
//     {
//         label: 'Mode of creation',
//         fieldName: 'modeOfCreation'
//     },
//     {
//         label: 'Total Records #',
//         fieldName: 'totalRecordsCount'
//     },
//     {
//         label: 'Success Records #',
//         fieldName: 'successrRecordsCount'
//     },
//     {
//         label: 'Error Records #',
//         fieldName: 'errorRecordsCount'
//     }    
// ];
  
     employeeColumns = [
        {
            label: 'Object',
            fieldName: 'objName'
        },
        
        {
            label: 'Id',
            type: "button",
            typeAttributes: {
                label :{
                    fieldName: 'actvityId'
                },
                name: "gotoActivity",
                variant: "base"
            }
           
        },
        // {
        //     label: 'Activity Id',
        //     fieldname: 'activityId'
        // },
        // {
        //     label: "Name",
        //     type: "button",
        //     typeAttributes: {
        //         label: {
        //             fieldName: "Name"
        //         },
        //         name: "gotoOpportunity",
        //         variant: "base"
        //     }
        // },
    {
        label: 'Mode of creation',
        fieldName: 'modeOfCreation'
    },
    {
        label: 'Total Records #',
        fieldName: 'totalRecordsCount'
    },
    {
        label: 'Success Records #',
        fieldName: 'successrRecordsCount'
    },
    {
        label: 'Error Records #',
        fieldName: 'errorRecordsCount'
    }
    ,
    {
        label: 'Requested UserId',
        fieldName: 'requestedBy'
    }
    
];

     @track isModalOpen = false;
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
    clickOK() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isModalOpen = false;
        this.deactivateValidationRulesForSobject();
    }
    deactivateValidationRulesForSobject() {
        deactivateValidationRulesForSobject({
            objectName: this.objectName
        }).then(data => {
            console.log('data deactivateValidationRulesForSobject  ', data);
            this.showSuccessToastOne(data);
        }).catch(error => {
            console.log('error deactivateValidationRulesForSobject  ', error.body.message);
            this.showErrorToast(error);
        });

    }


    getUiData(){
        var syncDetails = {};
        var syncDetailsArray = [];
        var inp = this.template.querySelectorAll(".sync");
        inp.forEach(item => {
            console.log('syncWithOrg  ', item.value);
            syncDetails[item.name] = item.value;
            syncDetailsArray.push(syncDetails);
            syncDetails = {};
        }, this);
        console.log(syncDetailsArray);
        return syncDetailsArray;
    }

    syncWithOrg(event) {
        console.log('syncWithOrg');
        let syncDetailsArray = this.getUiData();
        if (this.btnLabel != 'Authorized') {
            checkSync({
                    endpoint: syncDetailsArray[0].enpointURL
                })
                .then(data => {
                    if (data.isSuccess) {
                        let parsedD = JSON.parse(data.message);
                        let finalData = []
                        this.namedCredential = data.data;
                        this.btnLabel = 'Authorized';
                        this.toggleIconName = 'utility:check';
                        this.showSuccessToastOne('Sync Successful');
                        parsedD.records.forEach(rec=>{
                            console.log(rec.DeveloperName);
                            //finalData.
                            finalData.push({
                                name:rec.Label,apiName:rec.DeveloperName
                            })
                        });
                        console.log(Array.prototype.finalData);
                        this.otherOrgObjects = finalData;
                        console.log(this.otherOrgObjects);
                    } else {
                        this.btnLabel = 'Sync';
                        this.toggleIconName = undefined;
                        this.namedCredential = undefined;
                        this.showErrorToast(data.message);
                    }
                }).catch(error => {
                    console.log('error checkSync', error);
                    this.showErrorToast(error);
                });
        }
        console.log(' syncDetailsArray  ', syncDetailsArray);
    }

    handlePullcall(){
        let syncDetailsArray = this.getUiData();
        this.getDatafromExternal(true,syncDetailsArray[1].soqltext,false);
    }


    getDatafromExternal(isfromUI,squery,isTooling){
        
        getDataFromExternalOrg({
                sQuery: squery,
                endpoint: this.namedCredential,
                isTooling:isTooling
            })
            .then(data => {
                if (data.isSuccess) {
                    if(isfromUI){
                        this.parseFetchedData(data);
                    }else{
                        console.log(data);
                        this.relatedChildObjects = []
                        JSON.parse(data.message).records.forEach(element => {
                            if(element.RelatedListName){
                                this.relatedChildObjects.push(element.RelatedListName.toUpperCase());
                            }
                        });
                        this.createCSVData();
                    console.log('this.relatedChildObjects',this.relatedChildObjects);
                    }
                } else {
                    console.log(data.message);
                    
                    this.showErrorToast(JSON.parse(data.message)[0].errorCode);
                }
            }).catch(error => {
                console.log('error getDataFromExternalOrg', error);
                this.showErrorToast(error);
            });
    }
    

    parseFetchedData(data) {
        //let squery = data.data.toUpperCase();
        this.jsonData = data.message;
        this.jsonData = JSON.parse(this.jsonData);
        if(this.jsonData.totalSize==0){
            this.showInfoToast('No Records Found');
            return;
        }
        this.pullObjectName = this.jsonData.records[0].attributes.type;
        this.finalParentCol =[];
        this.finalChildCol =[];
        this.finalParentData = '';
        this.finalChildData = '';
        this.getDatafromExternal(false,"SELECT RelatedListName FROM RelatedListDefinition WHERE ParentEntityDefinitionId='"+this.pullObjectName+ "'",false);
    }
    
    createCSVData(){
        this.convertKeysToUpperCase(this.jsonData,this.pullObjectName);
        console.log('data--',this.finalParentCol);
        console.log('this.finalParentData--',this.finalParentData);
        console.log('this.finalChildData--',this.finalChildData);
        console.log('this.relatedChildObjects--',this.relatedChildObjects);
        let tempcsv
        tempcsv = this.finalParentCol.toString()+','+this.finalChildCol.toString()+'\n'; 
        let tempParent = this.finalParentData.replace(/^\s+|\s+$/g, '').split('\n');
        let tempchild = this.finalChildData.replace(/^\s+|\s+$/g, '').split('\n');
        for(let i in tempParent){
            if(i!==tempParent.length-1){
                if(tempchild[i]){
                    tempcsv += tempParent[i] + tempchild[i] + '\n';
                }else{
                    tempcsv += tempParent[i] + '\n'
                }
                
            }
        }
        this.csvData = tempcsv;
        this.showSuccessToastOne(this.jsonData.totalSize + ' records Pulled Successfully and Converted to CSV');
    }

    helperCSV(data,fileName){
        let dowEle = document.createElement('a');
        dowEle.href = 'data:text/csv;charset=utf-8,' + encodeURI(data);
        dowEle.target = '_self';
        dowEle.download = fileName+'.csv';
        document.body.appendChild(dowEle);
        dowEle.click();
    }

    downloadCSV() {
        // Creating anchor element to download
        this.helperCSV(this.csvData,this.pullObjectName);
        
    }
    downloadInsertCSV(){
        this.helperCSV(this.insertCSV,this.selectedObject.name);
    }

    convertKeysToUpperCase(obj,parentObj) {
        let cols = []
        let values = []
        for (let i in obj) {
            let k = i.toUpperCase();
            if(k !=='TOTALSIZE' && k !=='DONE' && k!=='TYPE' && k!=='URL' && k !=='ATTRIBUTES'){
                if (Object.prototype.toString.apply(obj[i]) === '[object Object]') {
                    this.convertKeysToUpperCase(obj[i],parentObj+'.'+k);
                } else if (Object.prototype.toString.apply(obj[i]) === '[object Array]') {
                    for (let j in obj[i]) {
                        this.convertKeysToUpperCase(obj[i][j],parentObj+'.'+j);
                        if(parentObj === obj.records[0].attributes.type){
                            this.finalParentData += '\n';
                            this.finalChildData += '\n'
                        }
                    }
                } else {
                    let splitData = parentObj.split('.');
                    let key;
                    if(splitData.length ===2){
                        key = k;
                    }else{
                        key = parentObj.substring(splitData[0].length+splitData[1].length+2)+'.'+k;
                    }      
                    if(/\d/.test(key)){
                        this.finalChildData += obj[i]+',';
                        if(this.finalChildCol.indexOf(key)===-1){
                            this.finalChildCol.push(key);
                        }
                        
                    }else if(this.relatedChildObjects.indexOf(key)===-1){
                        this.finalParentData +=  obj[i]+',';
                        if(this.finalParentCol.indexOf(key)===-1){
                            this.finalParentCol.push(key);
                        }
                    }
                }
            }   
        }
        return null;
    };

    handlePushRecordChange(event) {
        this.isPushFileInput = event.target.checked;
        console.log('this.isPushFileInput  ', this.isPushFileInput);

    }

    fileNotSupported = false;
    openfileUpload(event) {
        this.insertCSV = undefined;
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result; //.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'strCsv': base64
            }
            console.log(this.fileData)
        }
        reader.readAsText(file);
        //reader.readAsDataURL(file)
        if (this.fileData.filename.indexOf('csv') == -1) {
            this.fileNotSupported = true;
        } else
            this.fileNotSupported = false;
    }

    handleFileUpload() {
        console.log('this.fileData.strCsv',this.fileData.strCsv);
        pushDataToExternalOrg({
            csvdata:  this.fileData.strCsv,
            objectName: this.selectedObject.apiName,
            endpoint: this.namedCredential
        })
        .then(data => {
            if (data.isSuccess) {
                console.log(data);
                this.showSuccessToastOne('Successfully Created Records.')
                this.mapIds(data.data,data.message);
            } else{
                let parsData = JSON.parse(data.message);
                let temperrors;
                temperrors = '</br>';
                if(parsData.results){
                        parsData.results[0].errors.forEach(element => {
                        temperrors += '<p> <strong>Error :</strong>' + element.statusCode + '</p>' 
                        temperrors += '<p> <strong>Message :</strong>' + element.message + '</p>'
                        if(element.fields && element.fields.length>0){
                            temperrors += '<p><strong>Required Fields </strong>:' + element.fields + '</p>'
                        }
                    });
                }else{
                    temperrors += '<p> <strong>Error :</strong>' + parsData[0].errorCode + '</p>' 
                    temperrors += '<p> <strong>Message :</strong>' + parsData[0].message + '</p>'
                }
                this.insertError = temperrors;
                //divEle.innerHTML +=  temperrors;
                this.showErrorToast('Error at the Backend.');
            }
        }).catch(error => {
            console.log('error pushDataToExternalOrg', error);
            this.showErrorToast(error.body.message);
        });
    }

    mapIds(resData,Ids){
        console.log(resData);
        console.log(Ids);
        JSON.parse(Ids).results.forEach(record =>{
            resData=resData.replace(record.referenceId,record.id);
        });
        resData = resData.replace("referenceId","__Id");
        this.insertCSV = resData;
        console.log(resData);
    }

    handleSectionToggle(event){
        var divEle = this.template.querySelector(".accErroDiv");
        divEle.innerHTML = this.insertError;
        console.log(divEle);
    }

    handleSoqlChange(event){
        let inputQuery = event.target.value;
        if(inputQuery!==this.soqlQuery){
            this.csvData = undefined;
        }
        this.soqlQuery = inputQuery;
        this.disablePull = (inputQuery && inputQuery.length>0) ? false : true;
    }

    handleSynChange(event){
        let inputData = event.target.value;
        this.disableSync =  (inputData && inputData.length>0) ? false : true;
    }

    async handleValueSelected(event){
        console.log(event.detail);
        if(event.detail){
            this.selectedObject = event.detail;
            this.objectName=event.detail.name;
            console.log('handleValueSelected selectedObject  ',event.detail);
            console.log(event.detail.name);
            if(event.detail.name){
                
                await this.fetchFieldPicklist(event.detail.name);
                if(this.activeTabValue === 'PushRecords' || this.activeTabValue ==='Push/Pull'){
                    this.isFieldDisabled=true;
                }else{
                    this.isFieldDisabled=false;
                }

            }
        }else{
            this.selectedObject = undefined;
            this.insertCSV = undefined;
        }
       
    }

}
import { track,api, LightningElement } from 'lwc';
import insertRec from '@salesforce/apex/Innova_ToolingAPIHelper.insertRec';
import SequentialDataCreation from '@salesforce/apex/Innova_DataGeneratorCls.SequentialDataCreation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';




export default class Innova_DataSampleComponent extends LightningElement {
    @api allFieldsFromObject;
    @api objectName;
    @api relatedSobjName;
    @api isCreateRelated;

    @track listOfConditions;
    @track listOfRequiredFields;
    @track listOfOptionalFields;
    @api isFieldDisabled;
    activeTabValue;
    selectedUserId;
     showLoading = false;
    numValue = "5";
    totalTime;
    isOptionalFieldDate=false;
    isOptionalFieldDataPicklist=false;
    isOptionalFieldText=false;
    recKey= 'text';
   
    isOptionalDisplay =false;
    @api relatedRecPopup;
    cautionvar = 'Caution : Before creating the data, please make sure the system/custom validations are disabled or bypassed in the system.'+'\n'+'We advise to refer the validation rule set below.';
   
    customShowrelatedRecPopup() {            
        this.relatedRecPopup = true;
    }
 
  
		
		value = 'single';
    @track multiplerecords = false;
    
    get options() {
        return [
            { label: '1 child, 1 parent', value: 'single' },
            { label: '1 parent, multiple child', value: 'multiple' },
        ];
    }

				
 
		@api numberFieldValue;
    @api relatedrec(selectedUserId){
        console.log('FROM Data Sample Comp relatedrec  ');
        let startTime = Date.now();	
    console.log('multiple->',this.multiplerecords);
    console.log ('numberofrecords->',this.numberFieldValue, '   relatedSobjName  ',this.relatedSobjName);
		        this.relatedRecPopup = false;
                SequentialDataCreation({'count': this.numberFieldValue,'Parent':this.relatedSobjName,'child':this.objectName,'isMultiple':this.multiplerecords,recUserId:this.selectedUserId}).then(result=>{
                    //    if(str=='sucess'){
                       // this.showSuccessToast('Success');
                      // }
                      console.log('result is ',result, '  result.actvityId  ',result.actvityId);
                      this.totalTime = Date.now() - startTime;
                    if(result && (result.actvityId != '')){
                            console.log('SequentialDataCreation result   ',result);
                            let isRecordInserted=true;
                            let jsonToSend={'isRecordInserted':isRecordInserted,'result':JSON.parse(result)};
                            console.log('jsonToSend  ',jsonToSend);
                            const selectEvent= new CustomEvent('singlerecordinsertsuccess', {detail:jsonToSend});
                          // Dispatches the event.
                           this.dispatchEvent(selectEvent);
                            this.showSuccessToast('',this.totalTime/1000);
                        }else
                        {
                            console.log('SequentialDataCreation error   ',result)
                            this.showErrorToast(result);
                        }
                }).catch(error=>{
                    
                    console.log('SequentialDataCreation errr  ' ,error);
                    this.showErrorToast(error.body.message); 
        
                })
    }  

    connectedCallback() {   
        this.initData();
       
    }
   

    initData() {
        let listOfRequiredFields = [];
        this.createRow(listOfRequiredFields);
        this.listOfRequiredFields = listOfRequiredFields;
    }


   

    createRow(listOfRequiredFields) {
        console.log('createRow  Method listOfRequiredFields    ');
         let conditionObject = {};
        if(listOfRequiredFields.length > 0) {
            conditionObject.index = listOfRequiredFields[listOfRequiredFields.length - 1].index + 1;
        } else {
            conditionObject.index = 1;
        }
        conditionObject.Field = null;
        conditionObject.Value = null;
        listOfRequiredFields.push(conditionObject);
        
    }

    




     /**
     * Adds a new row
     */
      addNewRow() {
        this.createRow(this.listOfRequiredFields);
    }

        /**
     * Removes the selected row
     */
         removeRow(event) {
            let toBeDeletedRowIndex = event.target.name;
    
            let listOfRequiredFields = [];
            for(let i = 0; i < this.listOfRequiredFields.length; i++) {
                let tempRecord = Object.assign({}, this.listOfRequiredFields[i]); //cloning object
                if(tempRecord.index !== toBeDeletedRowIndex) {
                    listOfRequiredFields.push(tempRecord);
                }
            }
    
            for(let i = 0; i < listOfRequiredFields.length; i++) {
                listOfRequiredFields[i].index = i + 1;
            }
    
            this.listOfRequiredFields = listOfRequiredFields;
        }
    
           /**
         * Removes the selected row
         */
            removeRow(event) {
                let toBeDeletedRowIndex = event.target.name;
        
                let listOfRequiredFields = [];
                for(let i = 0; i < this.listOfRequiredFields.length; i++) {
                    let tempRecord = Object.assign({}, this.listOfRequiredFields[i]); //cloning object
                    if(tempRecord.index !== toBeDeletedRowIndex) {
                        listOfRequiredFields.push(tempRecord);
                    }
                }
        
                for(let i = 0; i < listOfRequiredFields.length; i++) {
                    listOfRequiredFields[i].index = i + 1;
                }
        
                this.listOfRequiredFields = listOfRequiredFields;
            }
            /**
     * Removes all rows
     */
             removeAllRows() {
                let listOfRequiredFields = [];
                this.createRow(listOfRequiredFields);
                this.listOfRequiredFields = listOfRequiredFields;
            }    

            selectedField(event){
                console.log('initial selectedField    ',JSON.stringify(this.listOfRequiredFields));
               
        
                let index = event.target.dataset.id;
                let fieldName = event.target.name;
                let value = event.target.value;
                console.log('index   ',index);
                console.log('fieldName',  fieldName);  
                console.log('value',  value);  
        
                if(JSON.stringify(this.listOfRequiredFields).indexOf(value) > 0 && fieldName != 'Value') {
                    console.log('Already Exist');
                    return this.showErrorToast('Field '+ value +' already Selected'); 
                }else{
                    console.log('NEW Field');
        
                }
        
                for(let i = 0; i < this.listOfRequiredFields.length; i++) {
                    console.log('in for selected ',this.listOfRequiredFields[i].Field);
                    console.log('in for value',  value);  
                    console.log('in for fieldName',  fieldName);  
                    if(this.listOfRequiredFields[i].index === parseInt(index)) {
                            this.listOfRequiredFields[i][fieldName] = value;
                        
                        
                    }
                }
   
            }

            
    showErrorToast(e){
        const evt= new ShowToastEvent({
            title:'Error',
            message:e,
            variant :'error',
            mode:'dismissable'
        })
        this.dispatchEvent(evt);
    }

    showSuccessToast(e,timeTaken){
        const evt= new ShowToastEvent({
            title:`Success!  Time Taken : ${timeTaken} ms`,
            message:e,
            variant :'success',
            mode:'dismissable'
        })
        this.dispatchEvent(evt);
    }

     ///////////////////////////////////////////////////Optional Field logic START/////////////////////////////////////////////////////


     handleOptionalFieldsDisplay(){
        this.isOptionalDisplay = this.isOptionalDisplay ? false : true;
        console.log('this.isOptionalDisplay ',this.isOptionalDisplay );
     this.initOptionalData();
    }
         /**
     * Init data Optional Field
     */
        initOptionalData(){
            let listOfOptionalFields = [];
            this.createRowforOptionalFields(listOfOptionalFields);
            this.listOfOptionalFields = listOfOptionalFields;

        }
            /**
     * Adds a new row for Optional Field
     */
             addNewRowOptional() {
                this.createRowforOptionalFields(this.listOfOptionalFields);
            }
        
            
    createRowforOptionalFields(listOfOptionalFields) {
        console.log('createRow  Method listOfOptionalFields    ');

        let conditionObject = {};
        if(listOfOptionalFields.length > 0) {
            conditionObject.index = listOfOptionalFields[listOfOptionalFields.length - 1].index + 1;
        } else {
            conditionObject.index = 1;
        }
        conditionObject.Field = null;
        conditionObject.Value = null;
        listOfOptionalFields.push(conditionObject);
        
    }


               /**
     * Removes the selected row from Optional Field
     */
                removeRowOptional(event) {
                    let toBeDeletedRowIndex = event.target.name;
            
                    let listOfOptionalFields = [];
                    for(let i = 0; i < this.listOfOptionalFields.length; i++) {
                        let tempRecord = Object.assign({}, this.listOfOptionalFields[i]); //cloning object
                        if(tempRecord.index !== toBeDeletedRowIndex) {
                            listOfOptionalFields.push(tempRecord);
                        }
                    }
            
                    for(let i = 0; i < listOfOptionalFields.length; i++) {
                        listOfOptionalFields[i].index = i + 1;
                    }
            
                    this.listOfOptionalFields = listOfOptionalFields;
                }

                  /**
         * Removes all rows
         */
        removeAllRows() {
            let listOfOptionalFields = [];
            this.createRowforOptionalFields(listOfOptionalFields);
            this.listOfOptionalFields = listOfOptionalFields;
        }

        selectedFieldOptional(event){
            console.log('initial selectedFieldOptional    ');  
            let index = event.target.dataset.id;
            console.log('Child index  ',index);
            let value;
            let fieldName = event.target.name;
            let fieldDataType;
            if(event.target.value){
            value= ((event.target.value).split('-')[0]).trim();
            fieldDataType=((event.target.value).split('-')[1]).trim();
            
            if(fieldDataType == 'DATE'){
                this.isOptionalFieldDate =true;
            }else if(fieldDataType == 'PICKLIST'){
                this.isOptionalFieldDataPicklist = true;
            }
            else{
                this.isOptionalFieldText=true;
            }
        }
            console.log('event.target;  ',event.target);
            console.log('fieldDataType  ',fieldDataType + ' isOptionalFieldDate ',this.isOptionalFieldDate);
            console.log('fieldName  ',   fieldName);
    
            if(JSON.stringify(this.listOfOptionalFields).indexOf(value) > 0 && fieldName != 'Value') {
                console.log('Already Exist');
                return this.showErrorToast('Field '+ value +' already Selected'); 
            }else{
                console.log('NEW Field');
    
            }
         for(let i = 0; i < this.listOfOptionalFields.length; i++) {
                if(this.listOfOptionalFields[i].index === parseInt(index)) {
                    if(value.toLowerCase() == 'true'){
                        this.listOfOptionalFields[i][fieldName] = Boolean(value); 
                    }else
                        this.listOfOptionalFields[i][fieldName] = value;      
                }
            }
        }

        handleSelectedOptionalFld(event){
            console.log('event log value ',event.detail.isOptDisplay);
            this.listOfOptionalFields = JSON.parse(JSON.stringify(event.detail.optField));
            console.log('event log value listOfOptionalFields ',this.listOfOptionalFields);

        }
      

    ///////////////////////////////////////////////////Optional Field logic END/////////////////////////////////////////////////////

    //retreive required field's  user Input
    getAllRequiredFiledInput(event)
    {
        console.log('getAllRequiredFiledInput');
        let container = {};
        let requiredArray=[];
       // console.log('event.target.label  ',event.target.label);
        var inp=this.template.querySelectorAll(".requiredFieldClsv");
        console.log('inp  ',inp);


        inp.forEach(function(element){
            if(element.name && element.value)
            {
            container['Field'] = (element.name).split('-')[0];
            container['Value']=element.value;
            requiredArray.push(container);
            }
            container={};            
        },this);
        this.listOfRequiredFields= requiredArray;
        console.log(' this.requiredArray ',requiredArray, '    inp  ',inp);

        
    }
 

    //startTime;
   // endTime;
   @api insertRecord(activeTabValue, selectedUserId){
   // console.log('344 event @api activeTabValue  ',activeTabValue);
   this.activeTabValue=activeTabValue;
   if(selectedUserId != ' ' && selectedUserId != null){
    this.selectedUserId=selectedUserId;
   }
   console.log('selectedUserId  ',this.selectedUserId);
   if(this.activeTabValue === 'Single'){
    this.inserSeltRecords();
    
   }
//    if(this.activeTabValue === 'Multiple'){
//     this.relatedRecPopup = true; 
//     return;
//    }
   
   }
  
    inserSeltRecords() {

        console.log('350 inserSelctRecords  ');
         let startTime = Date.now();	
       
        // console.log('isCreateRelated  ',this.isCreateRelated);
		// 		if(this.isCreateRelated){  
        //             this.relatedRecPopup = true; 
        //             return;}
        //after merge Index values are going to be duplicated and key 'Index' can be removed if required
        console.log('Submitted insertRecords' )
        
        this.getAllRequiredFiledInput();
        console.log('this.listOfRequiredFields.length   ',this.listOfRequiredFields.length,'   daat  ',JSON.stringify(this.listOfRequiredFields ));
        console.log('this.listOfRequiredFields[0].Field' ,this.listOfRequiredFields[0].Value)
        let tempDataArray;
        if(this.listOfRequiredFields.length >0 && this.listOfRequiredFields[0].Value != null){
            tempDataArray=this.listOfRequiredFields;
            console.log('129 tempDataArray  ',JSON.stringify(tempDataArray));
        }
                if(this.listOfOptionalFields && this.listOfOptionalFields.length >0 && this.listOfOptionalFields[0].Value != null){
                    tempDataArray=[...this.listOfRequiredFields,...this.listOfOptionalFields];
               // this.listOfRequiredFields = this.listOfRequiredFields.concat(this.listOfOptionalFields);
                }
                console.log('134 tempDataArray  ',tempDataArray);
                var dataSet;
                console.log('objName  '+this.objectName +'  recCount  '+this.numValue+'  str '+JSON.stringify(tempDataArray));
                // if(tempDataArray.length > 0 && (this.selectedUserId != null && this.selectedUserId != ' ')){
                //     dataSet=tempDataArray.map((item) => ({
                //         ...item,
                //         Field:'OwnerId',
                //         Value:this.selectedUserId  
                //     }));
                // }
                 dataSet = JSON.stringify(tempDataArray);
                console.log('dataSet DataSample',dataSet);
              //var dataSet = tempDataArray;
                this.numValue ='1';
                console.log('dataSet  '+dataSet);
                this.showHideSpinner();
                insertRec({objName: this.objectName, recCount:'1', str : dataSet,modeOfCreation:this.activeTabValue,recUserId:this.selectedUserId})
                .then(result=>{
                    this.totalTime = (Date.now() - startTime)/1000;
                    console.log('totalTime  ',this.totalTime);
                    this.showHideSpinner();
                    console.log('insertRec result  ',result);
                    console.log('result.insertedRecIds  ',result.insertedRecIds);
                    if(result && result.insertedRecIds != undefined){
                     //   this.initData();
                     if(result.insertedRecIds.length >0)
                        
                        console.log('result = ',result);
                        console.log('result = ',result);
                        this.showSuccessToast(' ',this.totalTime);
                      this. initData();
                      this.initOptionalData();
                    }
                    else{ 
                        this.showErrorToast(result.errorMessage);
                         return;
                    }
                   
                    if(this.template.querySelectorAll(".requiredFieldClsv")){
                        this.template.querySelectorAll(".requiredFieldClsv").forEach(function(element){                        
                            if(element.name && element.value)
                            {
                           // element.name= null;
                            element.value=null;
                            }
                        },this);
                    }
                    let isRecordInserted=true;
                    let jsonToSend={'isRecordInserted':isRecordInserted,'result':result};
                    console.log('jsonToSend  ',jsonToSend);
                    const selectEvent= new CustomEvent('singlerecordinsertsuccess', {detail:jsonToSend});
                  // Dispatches the event.
                   this.dispatchEvent(selectEvent);
                  

                   // this.listOfRequiredFields=[];
                    //this.listOfOptionalFields=[];
        
                }).catch(error=>{
                    this.showHideSpinner();
                    console.log('errr  ' ,error);
                    this.showErrorToast(error.body.message); 
        
                })
               
                
          console.log('listOfRequiredFields  ',JSON.stringify(this.listOfRequiredFields));
          console.log('listOfOptionalFields  ',JSON.stringify(this.listOfOptionalFields));
               
            }


            // Spinner 
            showHideSpinner() {
                console.log('showHideSpinner Called Before ',this.showLoading);
                // Setting boolean variable show/hide spinner
                this.showLoading = !this.showLoading;
                console.log('this.showLoading  '+this.showLoading);
            }



    
        

}
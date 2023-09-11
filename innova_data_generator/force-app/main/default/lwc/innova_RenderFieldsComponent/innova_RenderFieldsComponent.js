import { LightningElement,api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Innova_RenderFieldsComponent extends LightningElement {
    @api allFieldsFromObject
    @api rec;
     inputType='text';
    @api listOfOptionalFields;
    @api isOptionalDisplay;
    @api isFieldDisabled;
    @track selectedColumn;
    @track templistOfOptionalFields;



    renderedCallback(){
        console.log('initial tempIsOptDisp isOptionalDisplay    ', this.isOptionalDisplay,  '  isFieldDisabled  ',this.isFieldDisabled);  
        console.log('initial  allFieldsFromObject    ', this.allFieldsFromObject,  '  listOfOptionalFields  ',this.listOfOptionalFields); 

    }
    selectedFieldOptional(event){
        let queryData= this.template.querySelector('.ddlViewBy').value;
       
        this.templistOfOptionalFields=JSON.parse(JSON.stringify(this.listOfOptionalFields));
        //let tempIsOptDisp =  this.isOptionalDisplay;
        let allFields = JSON.parse(JSON.stringify(this.allFieldsFromObject));
        console.log('initial selectedFieldOptional    ', this.templistOfOptionalFields, 'allFields   ',allFields);  
        try{
       this.selectedColumn = allFields.find(item => item.custFldvalue === event.target.value);
        console.log('event.currentTarget.dataset.item;  ',event.target.dataset.item);
        }catch(e){
            console.log('errror ', e);
        }


        let index = event.target.dataset.id;
        console.log('Child index  ',index);//3
        console.log('event.target    ',event.target);
        let value;
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        console.log('fieldName   ',fieldName, '  fieldValue  ',fieldValue);
        let fieldDataType;
        if(fieldValue && fieldValue.includes(' - ')){
        value= ((event.target.value).split('-')[0]).trim();
        fieldDataType=((event.target.value).split('-')[1]).trim();
        
        if(fieldDataType == 'DATE'){
            this.inputType='date';
        }else if(fieldDataType == 'PICKLIST'){
            this.isOptionalFieldDataPicklist = true;
        }
        else if (fieldDataType == 'EMAIL'){
            this.inputType='email';
        }
        else{
            this.inputType='text';
            this.isOptionalFieldText=true;
            this.isOptionalFieldDataPicklist = false;
        }
    }else{
        value = fieldValue;
    }
        
        if(JSON.stringify(this.templistOfOptionalFields).indexOf(value) > 0 && fieldName != 'Value') {
            console.log('Already Exist');
            return this.showErrorToast('Field '+ value +' already Selected'); 
        }else{
            console.log('NEW Field');

        }
     for(let i = 0; i < this.templistOfOptionalFields.length; i++) {
            if(this.templistOfOptionalFields[i].index === parseInt(index)) {
                if(value.toLowerCase() == 'true'){
                    this.templistOfOptionalFields[i][fieldName] = Boolean(value); 
                }else
                    this.templistOfOptionalFields[i][fieldName] = value;      
            }
        }
        this.listOfOptionalFields=this.templistOfOptionalFields;
        const selectedEvent = new CustomEvent('selectedoptionalfld', { detail: {
                                    'optField' : this.listOfOptionalFields,
                                     'isOptDisplay':this.isOptionalDisplay   
                                     }});

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

      console.log('Child templistOfOptionalFields ',this.templistOfOptionalFields);   
    }


    selectedFieldOptionalPicklist(event){
        this.templistOfOptionalFields=JSON.parse(JSON.stringify(this.listOfOptionalFields));

        let index = event.target.dataset.id;

        let value;
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        value = fieldValue;
        for(let i = 0; i < this.templistOfOptionalFields.length; i++) {
            if(this.templistOfOptionalFields[i].index === parseInt(index)) {
                if(value.toLowerCase() == 'true'){
                    this.templistOfOptionalFields[i][fieldName] = Boolean(value); 
                }else
                    this.templistOfOptionalFields[i][fieldName] = value;      
            }
        }
        this.listOfOptionalFields=this.templistOfOptionalFields;
                const selectedEvent = new CustomEvent('selectedoptionalfld', { detail: {
                                    'optField' : this.listOfOptionalFields,
                                     'isOptDisplay':this.isOptionalDisplay   
                                     }});

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

      console.log('Child templistOfOptionalFields ',this.templistOfOptionalFields); 

    }

    showErrorToast(e){
        const evt= new ShowToastEvent({
            title:'Error',
            message:e,
            variant :'error',
            mode:'sticky'
        })
        this.dispatchEvent(evt);
    }
}
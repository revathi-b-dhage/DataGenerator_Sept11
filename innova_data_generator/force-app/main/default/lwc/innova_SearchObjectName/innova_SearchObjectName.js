import { LightningElement, api } from 'lwc';

const DELAY = 500;

export default class Innova_SearchObjectName extends LightningElement {

    @api placeholder = 'Search...'
    @api helpText = "custom search lookup";
    @api label = "Parent Account";
    @api required;
    @api selectedIconName = "standard:account";
    @api objectLabel = "API Name";
    @api sobjectList = [
        {name:'Account',apiName:'Account'},
        {name:'Contact',apiName:'Contact'}
    ];
    @api sobjectList2;
    @api recordsList;
    selectedRecordName;

    @api searchString = "";
    @api selectedRecordId;

    preventClosingOfSerachPanel = false;

    get showRecentRecords() {
        if (!this.recordsList) {
            return false;
        }
        return this.recordsList.length > 0;
    }

    //call the apex method
    searchObjectName() {
        let resultList = [];
        console.log(this.sobjectList);
        this.sobjectList.map(item=>{
            if(item.name.toLowerCase().indexOf(this.searchString.trim().toLowerCase())!==-1){
                resultList.push(item);
            }
        });  
        this.recordsList = resultList;   
    }

    get isValueSelected() {
        return this.selectedRecordId;
    }

    //handler for calling apex when user change the value in lookup
    handleChange(event) {
        
        this.searchString = event.target.value;
        console.log(this.searchString);
        if(this.searchString.length>0){
            this.searchObjectName();
        }else{
            this.recordsList = [];
        }
        
    }

    //handler for clicking outside the selection panel
    handleBlur() {
        this.recordsList = [];
        this.preventClosingOfSerachPanel = false;
    }

    //handle the click inside the search panel to prevent it getting closed
    handleDivClick() {
        this.preventClosingOfSerachPanel = true;
    }

    //handler for deselection of the selected item
    handleCommit() {
        this.selectedRecordId = "";
        this.selectedRecordName = "";
        const selectedEvent = new CustomEvent('valueselected');
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    //handler for selection of records from lookup result list
    handleSelect(event) {
        let selectedRecord = {
            name: event.currentTarget.dataset.name,
            apiName: event.currentTarget.dataset.id
        };
        this.selectedRecordId = selectedRecord.apiName;
        this.selectedRecordName = selectedRecord.name;
        this.recordsList = [];
        // Creates the event
        const selectedEvent = new CustomEvent('valueselected', {
            detail: selectedRecord
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }
    
    handleInputBlur(event) {
        console.log('handleInputBlur');
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (!this.preventClosingOfSerachPanel) {
                this.recordsList = [];
            }
            this.preventClosingOfSerachPanel = false;
        }, DELAY);
    }


}
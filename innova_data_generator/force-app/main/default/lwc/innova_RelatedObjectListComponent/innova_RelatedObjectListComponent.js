import { LightningElement,api, track, wire } from 'lwc';

export default class Innova_RelatedObjectListComponent extends LightningElement {
    
    @api relObj;
    @api selected;
    @api mouseIsOver;
    
    handleClick(event) {
        this.dispatchEvent(new CustomEvent('select', {
            detail: JSON.stringify({'objId':this.relObj.objId,'objName':this.relObj.apiName})
        }));
    }

    get divClass() {
        let cls = 'slds-p-around_small'
        if (this.selected ) {
            cls += ' slds-theme_inverse';
        } 
        if (this.mouseIsOver || this.relObj.isMaster) {
            cls += ' c-mouseover-border'
        }
        return cls;
    }

}
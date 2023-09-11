import { LightningElement,api } from 'lwc';

export default class Innova_PaginationComponent extends LightningElement {
 @api recordSize=1;
 currentPage =1
 totalRecords;
 totalPage = 0
 @api isNextEnabled;

 get records(){
    return this.visibleRecords
}

@api
    callFromParent() {
       console.log('from pagination' ,this.isNextEnabled);
      
       this.nextHandler();
       
    }

@api 
    set records(data){
        if(data){ 
            console.log('data   ',data + ' Data length '+data.length);
            this.totalRecords = data
            this.recordSize =  Number(this.recordSize);
            this.totalPage = Math.ceil(data.length/this.recordSize)
            console.log('this.totalPage  ',this.totalPage);
            console.log('this.totalRecords  ',this.totalRecords);
            console.log('this.recordSize  ',this.recordSize);
            this.updateRecords()
        }
    }

    get disablePrevious(){ 
        return this.currentPage<=1
    }
    get disableNext(){ 
        return this.currentPage>=this.totalPage
    }

    previousHandler(){ 
        if(this.currentPage>1){
            this.currentPage = this.currentPage-1
            this.updateRecords()
        }
    }

    nextHandler(){
        if(this.currentPage < this.totalPage){
            this.currentPage = this.currentPage+1
            this.updateRecords()
            this.isNextEnabled=true;
        }
    }

    updateRecords(){ 
        const start = (this.currentPage-1)*this.recordSize
        const end = this.recordSize*this.currentPage
        console.log('updateRecords -start  '+this.visibleRecords,'  this.currentPage ',this.currentPage, 'this.recordSize ',this.recordSize);
        console.log('updateRecords -end  '+end);
        this.visibleRecords = this.totalRecords.slice(start, end);
        console.log('updateRecords -this.visibleRecords  '+this.visibleRecords);
        this.dispatchEvent(new CustomEvent('update',{ 
            detail:{ 
                records:this.visibleRecords,
                currentPage:this.currentPage,
                totalPage:this.totalPage


            }
        }))
    }
}
import { LightningElement, track, wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import getRecords from '@salesforce/apex/MyDataTableController.getRecords';
import deleteRecordsApex from '@salesforce/apex/MyDataTableController.deleteRecords';
import cloneRecordsApex from '@salesforce/apex/MyDataTableController.cloneRecords';
import convertRecordsApex from '@salesforce/apex/MyDataTableController.convertRecords';
import { NavigationMixin } from 'lightning/navigation';
const COLS = [
    { label: 'Business Name', fieldName: 'BusinessName', type: 'text' },
    { label: 'Type', fieldName: 'Type', type: 'text', sortable: true},
    { label: 'Status', fieldName: 'Status', type: 'text', sortable: true },
    { label: 'Due Date', fieldName: 'DueDate', type: 'text', sortable: true }
];

export default class DatatableInterviewTest extends NavigationMixin(LightningElement) {
    columns = COLS;
    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    queryTerm = '%%';
    deleteDisabled = true;
    cloneDisabled = true;
    convertDisabled = true;
    convertLable = 'Convert to Opportunities | Sales';
    customModal = false;
    value = 'Lead';
    navigationPage = 'leadPage';
    tableData = [];

// dataTable initialize
    connectedCallback() {
        this.tableData = this.getAllRecords();
    }

// Populate clone, convert and delete button once select records in dataTable
    getSelectedName(event) {
         var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
         var leadNumber = 0;
         var oppNumber = 0;

         for (let i = 0; i < selectedRecords.length; i++) {
            if (selectedRecords[i].Type == 'Lead'){
                leadNumber = leadNumber + 1;
            }else{
                oppNumber = oppNumber + 1;
            }
         }

         if(leadNumber>0 && oppNumber == 0){
            this.convertDisabled = false;
            this.convertLable = 'Convert to Opportunities'
         } else if(leadNumber == 0 && oppNumber == 1){
            this.convertDisabled = false;
            this.convertLable = 'Convert to Sales'
         }  else{
            this.convertDisabled = true;
            this.convertLable = 'Convert to Opportunities | Sales'
         }

         if(selectedRecords.length > 0){
            this.deleteDisabled = false;
            this.cloneDisabled = false;
         }else if(selectedRecords.length == 0){
            this.deleteDisabled = true;
            this.cloneDisabled  = true;
         }
    }

// Delete records function
    deleteRecords(){
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        deleteRecordsApex({deleteRecWrapper: JSON.stringify(selectedRecords)})
        .then(result=>{
          this.tableData = result;
          this.template.querySelector('lightning-datatable').selectedRows=[];
          const toastEvent = new ShowToastEvent({
            title:'Success!',
            message:'Record deleted successfully',
            variant:'success'
          });
          this.dispatchEvent(toastEvent);
          this.convertDisabled = true;
          this.cloneDisabled = true;
          this.deleteDisabled = true;
        })
        .catch(error=>{  
          alert('Could not delete'+JSON.stringify(error));  
        })  
      }  

// Clone records function
      cloneRecords(){  
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        cloneRecordsApex({cloneRecWrapper: JSON.stringify(selectedRecords)})  
        .then(result=>{
          this.tableData = result;          
          this.template.querySelector('lightning-datatable').selectedRows=[];
          const toastEvent = new ShowToastEvent({  
            title:'Success!',
            message:'Record clone successfully',
            variant:'success'
          });
          this.dispatchEvent(toastEvent);
          this.convertDisabled = true;   
          this.cloneDisabled = true;   
          this.deleteDisabled = true;
          return refreshApex(this.tableData); 
        })
        .catch(error=>{  
          alert('Could not clone'+JSON.stringify(error));  
        })  
      }  

// Convert records function
      convertRecords(){  
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        convertRecordsApex({convertRecWrapper: JSON.stringify(selectedRecords)})  
        .then(result=>{
          this.tableData = result;          
          this.template.querySelector('lightning-datatable').selectedRows=[];
          const toastEvent = new ShowToastEvent({  
            title:'Success!',
            message:'Convert successfully',
            variant:'success'
          });
          this.dispatchEvent(toastEvent);
          this.convertDisabled = true;   
          this.cloneDisabled = true;   
          this.deleteDisabled = true;
          return refreshApex(this.tableData); 
        })
        .catch(error=>{  
          alert('Could not convert'+JSON.stringify(error));  
        })  
      }

//Search query function
    SearchNamehandleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
            this.getAllRecords();
        }
    }

//Query records
    getAllRecords(){
        getRecords({keyWord: this.queryTerm}).then(result => {
            this.tableData = result;
        })
        .catch(error => {
            console.log('error#' , error);
        })
    }
//datatable 'sortBy' function
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

//datatable 'sort' function
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.tableData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.tableData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    
//Popup Modal Section function
    //Popup choices
    get options() {
        return [
            { label: 'Lead', value: 'Lead' },
            { label: 'Opportunity', value: 'Opportunity' },
        ];
    }
    //Radio selection  
    handleRadioChange(event) {
        const selectedOption = event.detail.value;
        if (selectedOption == 'Lead'){
            this.navigationPage = 'leadPage';
        }else{
            this.navigationPage = 'oppPage';
        }
    }
    //Navigate to Lead or Opportunity create record page
        navigationLink(){
            this.customHideModalPopup();
        if (this.navigationPage =='leadPage'){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Lead',
                    actionName: 'new'
                },
            }).then(url => {
                window.open(url, "_blank");
            });  
            this.customHideModalPopup();      
        } else if (this.navigationPage =='oppPage'){
            this.customHideModalPopup();
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Opportunity',
                    actionName: 'new'
                },
            });
        }
     }
    //Modal Popup
     customShowModalPopup() {
        this.customModal = true;
    }
    customHideModalPopup() {
        this.customModal = false;
    }
}
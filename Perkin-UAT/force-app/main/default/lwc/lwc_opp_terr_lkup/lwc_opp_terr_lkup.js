import { LightningElement,wire, track,api } from 'lwc';
import getTerritoryName from'@salesforce/apex/lwc_opp_terr_lkup_cntlr.getTerritoryName';
import updateTerritoryonOpty from'@salesforce/apex/lwc_opp_terr_lkup_cntlr.updateTerritoryonOpty';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import C_LBL_Opp_Territory_LKUP_No_Matches from '@salesforce/label/c.C_LBL_Opp_Territory_LKUP_No_Matches';
export default class lwc_Opporunity_territory extends LightningElement {
    @track noValueReturned=false;
    @track isButtonDisabled=false;
    @track loadspin=false;
    @track selectedValue;
    @track options = [];
    @api recordId;
    @track valueselected;
    @track customMessage;
    

    @wire (getTerritoryName,{currentOpportunityId: '$recordId'})
	wiredTerritory({data, error}){
		if(data) {
            if(data.length<=0){
                this.customMessage=C_LBL_Opp_Territory_LKUP_No_Matches;
                this.noValueReturned=true;
                this.isButtonDisabled=true;
                return;
            }
            console.log('data'+JSON.stringify(data));
            let optionsValues = [];
            console.log('Returned Data Size ===> '+data.length);
            for(let i = 0; i < data.length; i++) {
                optionsValues.push({
                    label: data[i].tname,
                    value: data[i].tid
                })
            }
            this.options = optionsValues;
            window.console.log('optionsValues ===> '+JSON.stringify(optionsValues));
        }else {
			window.console.log('error ===> '+JSON.stringify(error));
		}
	}

    handleChange(event) {
        this.selectedValue = event.detail.value;
        var selvalue=this.options.filter(a=>a.value==this.selectedValue);
        console.log('selvalue'+JSON.stringify(selvalue));
        this.valueselected=selvalue[0].label;
        window.console.log('selected sValue is :'+this.selectedValue);
        
    }
    handleClick(event) {
        if(!this.selectedValue){
            const evt = new ShowToastEvent({
                title: 'Territory Not Selected',
                message: 'Kindly select a territory to proceed.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            return;
        }
        this.loadspin=true;
        updateTerritoryonOpty({ Territory: this.selectedValue,currentoppId: this.recordId })
		.then(result => {
            window.console.log(result);
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.loadspin=false;
            this.dispatchEvent(new CloseActionScreenEvent());
        })
		.catch(error => {
            window.console.log(error);
		})
    }

}
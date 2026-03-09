import { LightningElement } from 'lwc';
import scheduleAlert from '@salesforce/apex/LimitsApp.scheduleAlert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LimitsAppSchedulerStart extends LightningElement {
    handleSchedule(event){
        
        scheduleAlert()
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Scheduled Job Successfully Created',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please remove the existing Scheduled Job before Scheduling',
                        variant: 'error',
                    }),
                );
            });
          
    }

}
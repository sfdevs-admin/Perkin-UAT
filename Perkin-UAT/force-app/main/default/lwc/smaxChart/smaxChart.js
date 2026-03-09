import { LightningElement, wire, track, api } from 'lwc';
//importing the Chart library from Static resources
import chartjs from '@salesforce/resourceUrl/Chartjs';
import momentjs from '@salesforce/resourceUrl/Momentjs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//importing the apex method.
import getSjtDataSets from '@salesforce/apex/SMAX_PS_ChartController.getSjtDataSets';
import getTechManDataSets from '@salesforce/apex/SMAX_PS_ChartController.getTechManDataSets';

export default class FourthLwc extends LightningElement {

    @api label;
    @api recordId;
    @api chartLabel;
    @api horizon;
    @api chartType;  //  donut, line, bar

    @track isDonut;
    @track isLinear;
    @track isBar;

    chart;
    barchart;
    linechart;
    barconfig;
    lineconfig;
    chartjsInitialized = false;
    config;

    //--------------//
    // -- DOINIT -- //
    //--------------//
    connectedCallback() {
         this.chartConfigSetup();
    }
    // -- END DOINIT -- //

    //----------------//
    // -- STJ DATA -- //
    //----------------//
    _getStjs;
    _sjtdsRunning;

    @wire (getSjtDataSets, { sjtId: '$recordId', horizon: '$horizon' })
    sjts(response) {
        // recursion check
        if(this._sjtdsRunning == true) {
            return;
        }
        this._sjtdsRunning = true;

        this._getStjs = response;
        let error = response && response.error;
        let data = response && response.data;

        // ...if chart is invalid call chart setup method...
        if(!this.linechart) {
            // ...setup charts...
            this.validateLines();
        }

        // ...data and chart are valid...
        if(data && this.linechart) {
            var baseLine;
            // ...for each data returned...
            for(var key in data) {
                // ...if it is the baseline...
                if(data[key].x == 'base') {
                    // ...set the baseline...
                    baseLine = data[key].y;
                }
                else {
                    // ...set label...
                    this.linechart.data.labels.push(data[key].x);
                    // ...set actual line value...
                    this.linechart.data.datasets[0].data.push(data[key].y);
                    // ...set baseline value
                    this.linechart.data.datasets[1].data.push(baseLine);
                }
            }

            // ...set title...
            this.linechart.options.title.text = 'Standard Job Times vs Actuals for Last '+this.horizon+' month(s)';
            // ...refresh chart
            this.linechart.update();
            this.error = undefined;
        }
        else if(error) {
            this.error = error;
            this.accounts = undefined;
        }
        this._sjtdsRunning = false;
    }
    // -- END STJ DATA -- //

    //--------------------//
    // -- TECHMAN DATA -- //
    //--------------------//
    _getTechMans;
    _techManRunning;

    @wire(getTechManDataSets, { sjtId: '$recordId', horizon: '$horizon' })
    techMans(response) {
        // recursion check
        if(this._techManRunning == true) {
            return;
        }
        this._techManRunning = true;

        this._getTechMans = response;
        let error = response && response.error;
        let data = response && response.data;

        // ...if chart is invalid...
        if(!this.barchart) {
            // ...setup charts...
            this.validateLines();
        }

        // ..if data and chart are valid...
        if(data && this.barchart) {
            var baseLine;
            // ...for each data returned...
            for(var key in data) {
                // ...if it is the baseline...
                if(data[key].x == 'base') {

                    // TODO: figure out how to make this a line?
                    // ...set baseline value
                    this.barchart.data.labels.push('Standard');
                    this.barchart.data.datasets[0].data.push(data[key].y);
                }
                else {
                    // ...set label...
                    this.barchart.data.labels.push(data[key].x);
                    // ...set actual line value...
                    this.barchart.data.datasets[0].data.push(data[key].y);
                }
            }

            // ...set title...
            this.barchart.options.title.text = 'Average Job Times by Technician Manager';
            // ...refresh chart
            this.barchart.update();
            this.error = undefined;
        }
        else if(error) {
            this.error = error;
            this.accounts = undefined;
        }
        this._techManRunning = false;
    }
    // -- END TECHMAN DATA -- //

    //-------------------//
    // -- CHART SETUP -- //
    //-------------------//
    renderedCallback() {
        // run once check
        if(this.chartjsInitialized) return;
        this.chartjsInitialized = true;

        // call script loaders...
        Promise.all([loadScript(this,momentjs), loadScript(this,chartjs)])
        .then(() => {
            // ...setup charts
            this.validateLines();
        })
        .catch(error =>{
            this.dispatchEvent(new ShowToastEvent({
                title : 'Error loading ChartJS',
                message : error.message,
                variant : 'error',
            }),);
        });
    }

    validateLines() {
        // dom rendered check
        if(this.template.querySelector('canvas.line') == null) {
            return;
        }

        // setup line chart
        const linectx = this.template.querySelector('canvas.line').getContext('2d');
        this.linechart = new window.Chart(linectx, this.lineconfig);
        this.linechart.canvas.parentNode.style.height = '90%';
        this.linechart.canvas.parentNode.style.width = '90%';

        // setup bar chart
        const barctx = this.template.querySelector('canvas.bar').getContext('2d');
        this.barchart = new window.Chart(barctx, this.barconfig);
        this.barchart.canvas.parentNode.style.height = '90%';
        this.barchart.canvas.parentNode.style.width = '90%';
    }

    chartConfigSetup() {
        // overwrite check (if the chart is valid we don't want to mess with it)
        if(this.linechart) {
            return;
        }

        this.isLinear = true;
        this.lineconfig = {
            type: 'line',
            data :{
            datasets :[
                {
                    data: [],
                    label:'Average Job Time',
                    borderColor: "#3e95cd",
                    fill: false
                },
                {
                    data: [],
                    label:'Standard Job Time',
                    borderColor: "#c45850",
                    fill: false
                }]
            },
            options: {
                scales: {
                    xAxes: [{
                        type: 'time',
                        distribution: 'linear',
                        time: {
                            unit: 'day'
                        },
                        displayFormats: {
                            day: 'MMM DD'
                        }
                    }]
                },
                title: {
                    display: true,
                    text: ''
                }
            }
        };
        this.barconfig = {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: "Technician Managers",
                    backgroundColor: ["#c45850","#3e95cd", "#8e5ea2","#3cba9f","#e8c3b9","#3e95cd", "#8e5ea2","#3cba9f","#e8c3b9","#3e95cd", "#8e5ea2","#3cba9f","#e8c3b9"],
                    data: []
                }]
            },
            options: {
                legend: { display: false },
                title: {
                    display: true,
                    text: ''
                }
            }
        };
    }
    // -- END CHART SETUP -- //
}
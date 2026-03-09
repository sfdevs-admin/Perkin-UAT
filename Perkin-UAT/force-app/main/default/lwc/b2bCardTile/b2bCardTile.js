import { LightningElement ,api} from 'lwc';
export default class B2bCardTile extends LightningElement {

    @api imageUrl;
    // @api headline;
    // @api subtitle;
    // @api buttonLabel;
    @api buttonUrl;
    // @api description;

    // get showButton(){
    //     return this.buttonLabel && this.buttonUrl;
    // }
    // get urlImageAttribute(){
    //     return this.imageUrl ? 'background-image:url('+this.imageUrl+')' : '';
    // }
}
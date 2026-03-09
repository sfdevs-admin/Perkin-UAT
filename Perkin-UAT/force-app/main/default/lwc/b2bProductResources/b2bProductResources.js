import { LightningElement, api } from "lwc";
import getProductResources from "@salesforce/apex/B2B_ProductSpecificationController.getProductResourcesByProductId";
import mainTemplate from "./b2bProductResources.html";
import stencilTemplate from "./b2bProductResourcesStencil.html";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//labels 
import FILTER_ALL from '@salesforce/label/c.B2B_PDP_ProductResourcesAll';

export default class B2bProductResources extends LightningElement {
  static renderMode = "light";
  _productData;
  resourceMap = {};
  resourceTypes = [];
  selectedTypes = [];
  groupedResources = [];
  allSelected = true;
  productResourceExist = false;
  isLoading = true;

  labels = {
    FILTER_ALL
  };

  @api
  set productData(data) {
    this._productData = data;
    console.log("product resources ID:: ", this._productData.id);
    this.getAllResources();
  }
  get productData() {
    return this._productData;
  }

  getAllResources() {
    getProductResources({ productId: this._productData.id })
      .then((data) => {
        this.isLoading = false;
        console.log("product resources:: ", data);
        if (data.isSuccess) {
          let _data = data.data;

          if (_data && typeof _data === "object") {
            const totalResources = Object.values(_data).reduce(
              (acc, arr) => acc + (Array.isArray(arr) ? arr.length : 0),
              0
            );
            console.log("Total number of resources::", totalResources);

            if (totalResources > 0) {
              this.productResourceExist = true;
              this.resourceMap = _data;

              this.resourceTypes = Object.keys(_data)
                .map((type) => ({
                  label: `${type} (${_data[type]?.length || 0})`,
                  value: type
                }));

              this.selectedTypes = this.resourceTypes.map((item) => item.value);
              this.updateFilteredResources();
            } else {
              this.productResourceExist = false;
            }
          }
        } else {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error!",
              message: data.message,
              variant: "error",
              mode: "sticky"
            })
          );
        }
      })
      .catch((error) => {
        this.isLoading = false;
        console.log("error:: ", error);
      });
  }

  updateFilteredResources() {
    if (this.allSelected) {
      this.selectedTypes = this.resourceTypes.map((item) => item.value);
      this.groupedResources = this.selectedTypes.map((type) => ({
        type,
        records: this.resourceMap[type] || []
      }));
    } else if (this.selectedTypes.length === 0) {
      this.groupedResources = [];
    } else {
      this.groupedResources = this.selectedTypes.map((type) => ({
        type,
        records: this.resourceMap[type] || []
      }));
    }
  }

  handleCheckboxChange(event) {
    const updatedSelection = event.detail.value;

    if (updatedSelection.includes(FILTER_ALL)) {
      this.allSelected = true;
      this.selectedTypes = this.resourceTypes.map((item) => item.value);
    } else {
      this.allSelected = false;
      this.selectedTypes = updatedSelection;
    }

    const allResourceValues = this.resourceTypes.map((item) => item.value);
    if (
      updatedSelection.length > 0 &&
      updatedSelection.length === allResourceValues.length
    ) {
      this.allSelected = true;
    }
    this.updateFilteredResources();
  }

  handleAllCheckboxChange(event) {
    this.allSelected = event.target.checked;

    if (this.allSelected) {
      this.selectedTypes = this.resourceTypes.map((item) => item.value);
    } else {
      this.selectedTypes = [];
    }
    this.updateFilteredResources();
  }

  render() {
    if (this.isLoading) {
      return stencilTemplate;
    }
    return mainTemplate;
  }
}
import { LightningElement, track } from "lwc";
import getData from "@salesforce/apex/B2B_HomepageCarouselController.getData";
import mainTemplate from "./b2bHomepageCarousel.html";
import stencilTemplate from "./b2bHomepageCarouselStencil.html";

const VISSIBLE_CLASSES = "fade slds-show";
const HIDDEN_CLASSES = "fade slds-hide";
const DOT_VISSIBLE_CLASSES = "dot active";
const DOT_HIDDEN_CLASSES = "dot";

export default class B2bHomepageCarousel extends LightningElement {
  @track currentIndex = 0;
  slideIndex = 1;
  @track imagesData;
  @track images = [];
  isLoading = true;
  autoSlideInterval;
  
  next() {
    this.currentIndex = (this.currentIndex + 1) % this.images.length;
  }

  prev() {
    this.currentIndex =
      (this.currentIndex - 1 + this.images.length) % this.images.length;
  }

  async connectedCallback() {
    let mapP = {};
    await getData({
      mapParams: mapP
    })
      .then((res) => {
        this.isLoading = false;
        let response = JSON.parse(JSON.stringify(res));
        if (res.isSuccess) {
          if (response.imageDataList) {
            this.imagesData = JSON.parse(
              JSON.stringify(response.imageDataList)
            );
            this.images = this.imagesData.map((item, index) => {
              return index === 0
                ? {
                    ...item,
                    slideIndex: index + 1,
                    cardClasses: VISSIBLE_CLASSES,
                    dotClasses: DOT_VISSIBLE_CLASSES
                  }
                : {
                    ...item,
                    slideIndex: index + 1,
                    cardClasses: HIDDEN_CLASSES,
                    dotClasses: DOT_HIDDEN_CLASSES
                  };
            });
            this.startAutoSlide();
          }
        }
      })
      .catch((e) => {
        this.isLoading = false;
        console.error("getData catch---- " + JSON.stringify(e));
      });
  }

  backSlide() {
    let slideIndex = this.slideIndex - 1;
    this.slideSelector(slideIndex);
  }

  nextSlide() {
    let slideIndex = this.slideIndex + 1;
    this.slideSelector(slideIndex);
  }

  currentSlide(e) {
    let key = Number(e.target.dataset.key);
    this.slideSelector(key);
  }

  slideSelector(val) {
    if (val > this.images.length) {
      this.slideIndex = 1;
    } else if (val < 1) {
      this.slideIndex = this.images.length;
    } else {
      this.slideIndex = val;
    }

    this.images = this.images.map((item) => {
      return this.slideIndex === item.slideIndex
        ? {
            ...item,
            cardClasses: VISSIBLE_CLASSES,
            dotClasses: DOT_VISSIBLE_CLASSES
          }
        : {
            ...item,
            cardClasses: HIDDEN_CLASSES,
            dotClasses: DOT_HIDDEN_CLASSES
          };
    });
  }

  render() {
    if(this.isLoading){
        return stencilTemplate;
    }
    return mainTemplate;  
  }

  startAutoSlide() {
    this.autoSlideInterval = setInterval(() => {
      this.nextSlide();
    }, 7500);
  }

  disconnectedCallback() {
    if (this.autoSlideInterval) {
      clearInterval(this.autoSlideInterval);
    }
  }



}
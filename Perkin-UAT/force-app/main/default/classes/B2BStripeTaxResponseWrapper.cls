/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 09-17-2025
 * @last modified by  : Swati Chilap
 * @TestClass         : B2BStripeTaxResponseWrapperTest
**/

public class B2BStripeTaxResponseWrapper {
  // public String id;
  // public String object;
  public Integer amount_total;
  // public String currency;
  public CustomerDetails customer_details;
  public LineItems line_items;
  public Decimal tax_amount_exclusive;
  public List<TaxBreakdown> tax_breakdown;
  public ShippingCost shipping_cost;

  public class CustomerDetails {
    public Address address;
    public String address_source;
  }

  public class Address {
    public String city;
    public String country;
    public String line1;
    public String postal_code;
    public String state;
  }

  public class LineItems {
    // public String object;
    public List<LineItemData> data;
  }

  public class LineItemData {
    public String id;
    // public String object;
    public Integer amount;
    public Integer amount_tax;
    public String reference;
    public String tax_behavior;
    public String tax_code;
  }

  public class TaxBreakdown {
    public Decimal amount;
    public Boolean inclusive;
    public TaxRateDetails tax_rate_details;
    public String taxability_reason;
    public Decimal taxable_amount;
  }

  public class TaxRateDetails {
    public String country;
    public FlatAmount flat_amount;
    public String percentage_decimal;
    public String rate_type;
    public String state;
    public String tax_type;
  }

  public class FlatAmount {
    public Integer amount;
  }

  public class ShippingCost {
    public Integer amount;
    public Integer amount_tax;
    public String tax_behavior;
    public String tax_code;
  }

  // Helper to map tax amounts by reference (cartItemId)
  public Map<String, LineItemData> getLineItemsByReference() {
    Map<String, LineItemData> mapRef = new Map<String, LineItemData>();
    if (line_items != null && line_items.data != null) {
      for (LineItemData item : line_items.data) {
        if (item.reference != null) {
          mapRef.put(item.reference, item);
        }
      }
    }
    return mapRef;
  }

  public String getEstimatedTaxRate() {

    if (tax_breakdown != null && !tax_breakdown.isEmpty()) {
        for (TaxBreakdown tb : tax_breakdown) {
            if (tb != null && tb.amount > 0 && 
                tb.tax_rate_details != null && 
                tb.tax_rate_details.percentage_decimal != null) {
                return tb.tax_rate_details.percentage_decimal;
            }
        }
    }
    return '';
  }
}
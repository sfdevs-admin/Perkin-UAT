// public class B2BTaxResponseWrapper {
//     public String trnDocNum;
//     public String txwTrnDocId;
//     public Decimal txAmt;
//     public List<LineResult> lnRslts;
    
//     public class LineResult {
//         public String lnNm;
//         public String lnId;
//         public String txwLnId;
//         public Decimal txAmt;
//         public Decimal grossAmt;
//         public Decimal txRate;
//         public List<JurisdictionResult> jurRslts;
//     }

//     public class JurisdictionResult {
//         public Decimal txAmt;
//         public Decimal txRate;
//         public Decimal txableAmt;
//         public String txName;
//         public String txNameID;
//         public String txJurUIDStatePrv;
//     }
// }

public class B2BTaxResponseWrapper {
    public String trnDocNum;
    public String txwTrnDocId;
    public Decimal txAmt;
    public List<LineResult> lnRslts;
    public Boolean mergedResult;
    public List<TaxDecisionSet> txDecisSets;

    public class LineResult {
        public String lnNm;
        public String lnId;
        public Decimal txAmt;
        public Decimal grossAmt;
        public List<JurisdictionResult> jurRslts;
    }

    public class JurisdictionResult {
        public Decimal txAmt;
        public Decimal txRate;
        public Decimal txableAmt;
        public Decimal xmptAmt;
        public String txName;
        public String txTp;
        public Decimal txPaidToDt;
        public Decimal txablePaidToDt;
        public String leasePmtTp;
        public String txJurUIDCntry;
        public String txJurUIDStatePrv;
        public String txJurUIDJurTp;
        public String txJurUIDStatePrvISO;
        public String txJurUIDCntryISO;
        public String txJurUIDCityCntyDist;
        public List<TaxDecisionSet> txDecisSets;
    }

    public class TaxDecisionSet {
        public String txDecisSetTp;
        public List<List<TaxDecision>> txDeciss;
    }

    public class TaxDecision {
        public String severity;
        public String id;
        public String dscrp;
        public String dtls;
        public Map<String, Object> attrbs;
    }
}
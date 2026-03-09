public class FormatDateInLanguage {

    static Map<Integer,String> monthToNameLabels = new Map<Integer,String>{
        1 => 'Month_Abbreviation_January',
        2 => 'Month_Abbreviation_February',
        3 => 'Month_Abbreviation_March',
        4 => 'Month_Abbreviation_April',
        5 => 'Month_Abbreviation_May',
        6 => 'Month_Abbreviation_June',
        7 => 'Month_Abbreviation_July',
        8 => 'Month_Abbreviation_August',
        9 => 'Month_Abbreviation_September',
        10 => 'Month_Abbreviation_October',
        11 => 'Month_Abbreviation_November',
        12 => 'Month_Abbreviation_December'
    };

    public class Input {
        @InvocableVariable
        public Date inputDate;  
        @InvocableVariable 
        public String localeCode; 
    }

    public class Output {
        @InvocableVariable
        public String formattedDate;
    }

    @InvocableMethod(label='Format Date in Language' description='Formats a date using custom labels for month abbreviations based on local code.')
    public static List<Output> formatDate(List<Input> inputs) {
        List<FormatDateInLanguage.Output> results = new List<FormatDateInLanguage.Output>();
       
        for (Input i : inputs) {
            Output o = new Output();
            o.formattedDate = formatDate(i.inputDate, i.localeCode);
            results.add(o);
        }

        return results;
    }

    public static String formatDate(Date inputDate, String localeCode) {
        if (inputDate != null) {
            String year = String.valueOf(inputDate.year());
            String day = String.valueOf(inputDate.day());
            Integer month = inputDate.month();
            String monthAbbrev = LocaleLabelUtil.getLabel(monthToNameLabels.get(month), localeCode);

            return day + '-' + monthAbbrev + '-' + year;
        }
        return null;
    }
}
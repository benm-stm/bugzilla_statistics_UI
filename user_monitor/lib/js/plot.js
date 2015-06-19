// Data array for the graph
var data;
var partner_array = [];

$(document).ready(OnReady);
$(document).ready(Calendar);

// Format and activate the calendar for both textfields
function Calendar(){
    $(".input-daterange_right").datepicker({
    format: "yyyy-mm-dd",
    todayBtn: true,
    clearBtn: true,
    autoclose: true,
    orientation: "top right"
    });
    $(".input-daterange_left").datepicker({
    format: "yyyy-mm-dd",
    todayBtn: true,
    clearBtn: true,
    autoclose: true,
    orientation: "top left"
    });
    $("#activity_year").datepicker({
    format: "yyyy",
    viewMode: "years", 
    minViewMode: "years",
    autoclose: true,
    orientation: "auto"
    });
}
            
// when the form is submitted
function OnReady(){
    $("form").submit(OnSubmit);
}
function OnSubmit(){
    init_divs();
    $("#progress_bar").removeClass('hidden').fadeIn("slow", function(){
            data = json_filter($('#begin_date').val(), $('#end_date').val());
            if(typeof data == "undefined"){
                init_divs();
                OnFailure();
            }
            else {
                init_divs();
                OnSuccess();
            }
        return data;
    });
    return false;
}
function OnSuccess(){
        user_stats_on_success();
}

function OnFailure(){
    $( "#alert" ).addClass( "alert-warning" );
    $( "#alert" ).html(" There is no available data for the given date range !");
    $( "#alert" ).removeClass('hidden').fadeIn("slow");
}

function user_stats_on_success() {
    $.getScript("/user_monitor/lib/js/linechart.js");
    $.getScript("/user_monitor/lib/js/user_list.js");
    
    $("#plot").removeClass('hidden').fadeIn("slow");
    $("#side_bar").addClass('well well-sm');
    $("#side_bar").removeClass('hidden').fadeIn("slow");
    $("#download").removeClass('hidden').fadeIn("slow");

}

function init_divs() {
    $("#plot").hide();
    $("#alert").hide();
    $("#side_bar").hide();
    $("#progress_bar").hide();
    $("#download").hide();

    $("#plot").empty();
    $("#accordion").empty();
    $("#partners").empty()
}

function json_filter(begin_date, end_date) {
    var tmp ="";
    var json_date = "";
    var in_range = 0;
    var tmp_json = [];
    for (var i = 0; i < json_data.stats.length; i++) {
        json_date = json_data.stats[i].year+'-'+json_data.stats[i].month+'-'+json_data.stats[i].day;
        if (json_date == begin_date || in_range == 1) {
            in_range = 1;
            tmp = json_data.stats[i].users.split(", "); 
            var size = tmp.length;
            if (tmp == "") {
                size --;
            }
            tmp_json.push({"end_time":json_date,"value":size,"users":json_data.stats[i].users});
            //extract partner name
            add_unique (partner_array, json_data.stats[i].users);

            if (json_date == end_date) {
                return tmp_json;
            }
        }            
    }
}
//extract the partner name of the email
function extract_partner (str) {
    var n = str.indexOf("@"); 
    str = str.substr(n);
    n = str.indexOf(".");
    return str.substr(1, n-1);
}

//add unique partner name to a table
function add_unique (arr, str) {
    var partner = extract_partner(str);
    if(arr.indexOf(partner) == -1) {
        arr.push(partner);
    }
}

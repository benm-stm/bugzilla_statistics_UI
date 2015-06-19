var total = 0
var user_exist = 0;

for (var i = 0; i < data.length; i++) {
    if (data[i].value > 0) {
        user_exist = 1;
        $("#accordion").append('<div class="panel panel-default">'+
                            '<div class="panel-heading">'+
                                '<h4 class="panel-title">'+
                                    '<a data-toggle="collapse"  href="#collapse'+i+'">'+
                                        '<i class="indicator glyphicon glyphicon-calendar"> '+
                                            '<span class="label label-default">'+
                                                data[i].end_time.toLocaleDateString()+
                                            '</span>'+
                                        '</i>'+
                                        '<span class="badge pull-right">'+
                                            data[i].value+' user(s)'+
                                        '</span>'+
                                    '</a>'+
                                '</h4>'+
                            '</div>'+
                            '<div id="collapse'+i+'" class="panel-collapse collapse off">'+
                                '<div class="panel-body">'+
                                      data[i].users.replace(/\, /g, '<br>')+
                                '</div>'+
                            '</div>'+
                        '</div>');
    }
}
if (user_exist === 0) {
    $("#accordion").append('<div id="alert_sidebar" class="alert alert-warning" role="alert">There is no active users in the given date range !</div>');
} else {
    for (var i = 0; i < partner_array.length; i++) {
        $("#partners").append("<span class='label label-info'>"+partner_array[i]+"</span> ");
    }
}


json_data = (function () {
    var json = null;
    $.ajax({
        'async': false,
        'global': false,
        'url': 'data.json',
        'dataType': "json",
        'success': function (data) {
            json = data;
        }
    });
    return json;
})(); 

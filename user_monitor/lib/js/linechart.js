
var m = [80, 80, 80, 80],
    w = $("#plot").width()- m[1] - m[3],
    //w = 1100 - m[1] - m[3],
    h = 650 - m[0] - m[2],
    parse = d3.time.format("%Y-%m-%d").parse;


var x = d3.time.scale().range([0, w]),
    y = d3.scale.linear().range([h, 0]),
    xAxis = d3.svg.axis().scale(x).tickSize(-h).tickFormat(d3.time.format("%d/%m")),
    yAxis = d3.svg.axis().scale(y).ticks(2).orient("right");

var area = d3.svg.area()
    .interpolate("linear")
    .x(function (d) {
    return x(d.end_time);
})
    .y0(h)
    .y1(function (d) {
    return y(d.value);
});

var line = d3.svg.line()
    .interpolate("linear")
    .x(function (d) {
    return x(d.end_time);
})
    .y(function (d) {
    return y(d.value);
});

data.forEach(function (d) {
    d.end_time = parse(d.end_time);
    d.value = +d.value;
});

var total = 0
for (var i = 0, len = data.length; i < len; i++) {
    total += data[i].value;
}

x.domain([data[0].end_time, data[data.length - 1].end_time]);
y.domain([0, d3.max(data, function (d) {
    return d.value;
})]).nice();

var svg = d3.select("#plot").append("svg:svg")
    .attr("width", w + m[1] + m[3])
    .attr("height", h + m[0] + m[2])
    .attr("id", "svg")
    .append("svg:g")
    .attr("transform", "translate(" + m[3] + "," + m[0] + ")");

svg.append("svg:path")
    .attr("class", "area")
    .attr("d", area(data));

svg.append("svg:g")
    .attr("class", "x axis")
    .attr("transform", "translate(1," + h + ")")
    .call(xAxis);

svg.append("svg:g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + w + ",0)")
    .call(yAxis);

svg.selectAll("line.y")
    .data(y.ticks(5))
    .enter().append("line")
    .attr("x1", 0)
    .attr("x2", w)
    .attr("y1", y)
    .attr("y2", y)
    .style("stroke", "#000000")
    .style("stroke-opacity", 0.06);

svg.append("svg:path")
    .attr("class", "line")
    .attr("d", line(data));

svg.append("svg:text")
    .attr("x", 80)
    .attr("y", -10)
    .attr("text-anchor", "end")
    .text('User stats')
    .style("stroke", "#444")
    .style("fill", "#000")
    .style("stroke-width", .2)
    .style("font-size", "12px")
    .style("font-weight", "bold");

svg.append("svg:text")
    .attr("x", w)
    .attr("y", -10)
    .attr("text-anchor", "end")
    .text('total users = ' + total)
    .style("stroke", "#008cdd")
    .style("fill", "#008cdd")
    .style("stroke-width", .2)
    .style("font-size", "12px")
    .style("font-weight", "bold");

svg.selectAll("circle")
    .data(data)
    .enter().append("circle")
    .attr("r", 4)
    .attr("class", "tooltip_selector")
    .attr("data-placement", "top")
    .attr('data-original-title', '')
    //'Date : '+x(d.end_time)+'<br>Value :'+y(d.value)
    .attr('cx', function (d) {
    return x(d.end_time);
})
    .attr('cy', function (d) {
    return y(d.value);
});

var paragraphs = document.getElementsByTagName("p");
for (var i = 0; i < paragraphs.length; i++) {
  var paragraph = paragraphs.item(i);
  paragraph.style.setProperty("color", "white", null);
}


(function($) {
    $('.tooltip_selector').tooltip({
    html: true
    });
})(jQuery); 

$('svg circle').tipsy({ 
    delayIn: 0,      // delay before showing tooltip (ms)
    delayOut: 0,     // delay before hiding tooltip (ms)
    fade: true,     // fade tooltips in/out?
    fallback: '',    // fallback text to use when no tooltip text
    gravity: 'w',    // gravity
    html: true,     // is tooltip content HTML?
    live: false,     // use live event support?
    offset: 0,       // pixel offset of tooltip from element
    opacity: 0.7,    // opacity of tooltip
    title: 'title',  // attribute/callback containing tooltip text
    trigger: 'hover', // how tooltip is triggered - hover | focus | manual
        title: function() {
          var d = this.__data__;
	  var pDate = d.end_time;
          return 'Date: ' + pDate.getDate() + "/" + (pDate.getMonth()+1) + "/" + pDate.getFullYear() + '<br>Value: ' + d.value; 
        }
      });
      
function updateWindow(m){
    w = $("#plot").width()- m[1] - m[3];
    svg.attr("width", w);
}
//window.onresize = updateWindow(m);
$(window).resize(function() {
    updateWindow(m);
});


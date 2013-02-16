var webSocket;
var consoleContents = [];
var maxConsoleLength = 50;

function init() {
    if ("WebSocket" in window) {
        webSocket = new WebSocket("ws://" + location.host + "/console_websocket");
        webSocket.onmessage = function(event) {
            console.log("Received data");
            append_console_data(event.data);
        }
        webSocket.onopen = function(event) {
            console.log("Socket opened");
            append_console_data("Web socket open");
        }
        webSocket.onclose = function() {
            console.log("Socket closed");
            append_console_data("Web socket closed");
        }

        document.getElementById("input_field").focus();
    } else {
        alert("Your browser does not support WebSockets");
        // Websocket not supported
    }
}

function send_data() {
    var input_field_data = document.getElementById("input_field").value;
    clear_input_field();
    webSocket.send(input_field_data);
    append_console_data(input_field_data);
}

function append_console_data(data) {
    var lines  = data.split(/\n/);

    consoleContents = consoleContents.concat(lines);
    var overflow = consoleContents.length - maxConsoleLength;
    if(overflow > 0) {
        consoleContents = consoleContents.slice(overflow);
    }
    
    document.getElementById("console").innerHTML = "<li>" + consoleContents.join("</li><li>") + "</li>";
}

function clear_input_field() {
    document.getElementById("input_field").value = "";
}

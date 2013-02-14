var webSocket;

function init() {
    if ("WebSocket" in window) {
        webSocket = new WebSocket("ws://" + location.host + "/console_websocket");
        webSocket.onmessage = function(event) {
            console.log("Received data");
            append_console_data(event.data);
        }
        webSocket.onopen = function(event) {
            console.log("Sending data");
            webSocket.send("Test data woot!");
            append_console_data("Web socket open");
        }
    } else {
        // Websocket not supported
    }
}

function send_data() {
    webSocket.send(document.getElementById("input_field").value);
    clear_input_field();
}

function format_console_line(data) {
    return "<li>" + data + "</li>";
}

function append_console_data(data) {
    var old_value = document.getElementById("console").innerHTML;
    document.getElementById("console").innerHTML = old_value + format_console_line(data);
}

function clear_input_field() {
    document.getElementById("input_field").value = "";
}

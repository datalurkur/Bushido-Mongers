var webSocket;
var consoleContents = [];
var commandHistory  = [];
var commandIndex;
var maxConsoleLength = 50;
var maxHistoryLength = 50;

var key_handler = function(e) {
    if(e.keyCode == 38 && commandHistory.length > 0) {
        if(commandIndex == undefined) { commandIndex = commandHistory.length - 1; }
        else if(commandIndex > 0)     { commandIndex -= 1;                        }

        document.getElementById("input_field").value = commandHistory[commandIndex];
    } else if(e.keyCode == 40) {
        var newContents;
        if(commandIndex != undefined && commandIndex < commandHistory.length - 1) {
            commandIndex += 1;
        } else if(commandIndex == commandHistory.length - 1) {
            commandIndex = undefined;
        }
        if(commandIndex == undefined) {
            document.getElementById("input_field").value = "";
        } else {
            document.getElementById("input_field").value = commandHistory[commandIndex];
        }
    }
}

function init() {
    if("WebSocket" in window) {
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
        document.getElementById("input_field").addEventListener('keydown', key_handler, false);
        document.getElementById("input_field").addEventListener('keypress', key_handler, false);
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

    commandHistory.push(input_field_data);
    var overflow = commandHistory.length - maxHistoryLength;
    if(overflow > 0) {
        commandHistory = commandHistory.slice(overflow);
    }

    append_console_data(input_field_data);
    commandIndex = undefined;
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

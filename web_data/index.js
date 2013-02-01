var activeTab;

function init() {
    activeTab = "default";
    showTab(activeTab);
}

function showTab(tabName) {
    document.getElementById(tabName).setAttribute("class", "tab");
}

function hideTab(tabName) {
    document.getElementById(tabName).setAttribute("class", "hiddentab");
}

function focusTab(lobbyName) {
    hideTab(activeTab);
    showTab(lobbyName);
    activeTab = lobbyName;
}

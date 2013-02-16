var activeTab;

function getQueryParams(queryString) {
    queryString = queryString.split("+").join(" ");

    var params = {};
    var tokens;
    var re = /(\?|\&)([^=]+)=([^&]*)/g;

    while (tokens = re.exec(queryString)) {
        params[decodeURIComponent(tokens[2])] = decodeURIComponent(tokens[3]);
    }

    return params;
}

function getFragment() {
    var re = /#(.*)/g;
    var query = document.location.hash;
    var fragment = re.exec(query);
    if(fragment == undefined || fragment == null) {
        return null;
    } else {
        return fragment[1];
    }
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

function init() {
    var focus = getFragment();
    if(focus == undefined || focus == null) {
        activeTab = "default";
    } else {
        activeTab = focus;
    }
    showTab(activeTab);
}

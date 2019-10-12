function newRootBar(param) {
    var container = document.getElementById("container");
    _newBar(container, param);
    return;
}

function containerDomId(barid) {
    return "container-" + barid;
}

function barDomId(barid) {
    return "bar-" + barid;
}

function getBarContainerById(barid) {
    return document.getElementById(containerDomId(barid));
}

function getBarDomById(barid) {
    return document.getElementById(barDomId(barid));
}

function _newBar(container, param) {
    var barContainer = document.createElement("div");
    var barWrapper = document.createElement("div");
    var barDiv = document.createElement("div");
    var msgWrapper = document.createElement("div");
    var msgDiv = document.createElement("div");
    barContainer.id = containerDomId(param.barid);
    barDiv.id = barDomId(param.barid);
    barContainer.classList.add("progressContainer");
    barWrapper.classList.add("progressWrapper");
    barDiv.classList.add("progress");
    msgWrapper.classList.add("messageWrapper");
    msgDiv.classList.add("message");
    barWrapper.appendChild(barDiv);
    msgWrapper.appendChild(msgDiv);
    barWrapper.appendChild(msgWrapper);
    barContainer.appendChild(barWrapper);
    container.appendChild(barContainer);
    _setProgress(barDiv, param);
}

function setProgress(param) {
    var barDiv = getBarDomById(param.barid);
    _setProgress(barDiv, param);
    removeFinished(param);
    return;
}

function _setProgress(barDiv, param) {
    barDiv.style.width = (param.progress * 100) + "%";
    txt = param.title;
    if (param.message) {
	txt = txt + " " + param.message;
    };
    txt = txt + " (" + param.progresstext + ")";
    msgElm = barDiv.parentNode.getElementsByClassName("message")[0];
    msgElm.innerText = txt;
}

function newSubBar(param) {
    var container = getBarContainerById(param.parentid);
    _newBar(container, param);
    return;
}

function removeFinished(param) {
    param.finished.forEach(function (barid) {
	div = getBarContainerById(barid);
	div.parentNode.removeChild(div);
    });
    return;
}

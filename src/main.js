class ProgressBar {
    constructor(param, container) {
	this.barContainer = document.createElement("div");
	this.barWrapper = document.createElement("div");
	this.barDiv = document.createElement("div");
	this.msgWrapper = document.createElement("div");
	this.msgDiv = document.createElement("div");
	this.barContainer.id = this.constructor.containerDomId(param.barid);
	this.barDiv.id = this.constructor.barDomId(param.barid);
	this.barContainer.classList.add("progressContainer");
	this.barWrapper.classList.add("progressWrapper");
	this.barDiv.classList.add("progress");
	this.msgWrapper.classList.add("messageWrapper");
	this.msgDiv.classList.add("message");
	this.barWrapper.appendChild(this.barDiv);
	this.msgWrapper.appendChild(this.msgDiv);
	this.barWrapper.appendChild(this.msgWrapper);
	this.barContainer.appendChild(this.barWrapper);
	container.appendChild(this.barContainer);
	this._setProgress(param);

	this.constructor.bars[param.barid] = this;
    }

    // Doesn't work with Electron 4.x:
    // static bars = {};

    static lookup(barid) {
	return this.bars[barid]
    }

    static containerDomId(barid) {
	return "container-" + barid;
    }

    static barDomId(barid) {
	return "bar-" + barid;
    }

    _setProgress(param) {
	this.barDiv.style.width = (param.progress * 100) + "%";
	var txt = param.title;
	if (param.message) {
	    txt = txt + " " + param.message;
	};
	txt = txt + " (" + param.progresstext + ")";
	if (param.etatext) {
	    txt = txt + " " + param.etatext;
	}
	this.msgDiv.innerText = txt;
    }

    setProgress(param) {
	this._setProgress(param);
	this.constructor.removeFinished(param);
    }

    static removeFinished(param) {
	var bars = this.bars;
	param.finished.forEach(function (barid) {
	    var bar = ProgressBar.lookup(barid);
	    var div = bar.barContainer;
	    div.parentNode.removeChild(div);
	    delete bars[barid];
	});
    }

    newSubBar(param) {
	return new ProgressBar(param, this.barContainer);
    }
}
ProgressBar.bars = {};

function newRootBar(param) {
    var container = document.getElementById("container");
    new ProgressBar(param, container);
}

function setProgress(param) {
    ProgressBar.lookup(param.barid).setProgress(param);
}

function newSubBar(param) {
    ProgressBar.lookup(param.parentid).newSubBar(param);
}

function removeFinished(param) {
    ProgressBar.removeFinished(param);
}

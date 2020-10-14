var exec = require('cordova/exec');


function materialcircle() {}

materialcircle.prototype.show = function () {
    exec(null, null, 'MaterialCircle', 'show', []);
};

materialcircle.prototype.hide = function () {
    exec(null, null, 'MaterialCircle', 'hide', []);
};

module.exports = new materialcircle();

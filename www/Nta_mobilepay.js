var exec = require('cordova/exec');

exports.makePayment = function(price,uuid,appswitch_id,url_scheme) {
	console.log("Vi har følgende uuid:"+uuid);
	success_ = function(data){
		console.log("We got a success back: "+data);
	}
	error_ = function(data){
		console.log("We got an error back: "+data);
	}
    exec(success_, error_, "Nta_mobilepay", "makePayment", [price,uuid,appswitch_id,url_scheme]);
};
exports.echo = function(arg0, success, error) {
    exec(success, error, "Nta_mobilepay", "echo", [arg0]);
};

exports.echojs = function(arg0, success, error) {
    if (arg0 && typeof(arg0) === 'string' && arg0.length > 0) {
        success(arg0);
    } else {
        error('Empty message!');
    }
};

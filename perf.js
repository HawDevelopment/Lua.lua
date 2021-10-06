const exec = require("child_process").exec;
const fs = require("fs");

const perf_dir = "./logs";

function execute(command, callback) {
	exec(command, function (err, stdout, stderr) {
		callback(stdout);
	});
}

execute("lua Lua.lua --debug run test.lua", (message) => {
	fs.readdir(perf_dir, (_, files) => {
		var date = new Date();
		date = date.getMonth() + 1 + "/" + (date.getDate() > 9 ? "" : "0") + date.getDate() + "/" + date.getFullYear();

		message = "(" + date + ")\n" + message;

		var length = files.length + 1;
		var name = "0".repeat(4 - length.toString().length) + length;

		var file = perf_dir + "/Perf-" + name + ".txt";
		fs.writeFile(file, message, (err) => {
			if (err) throw err;
		});
	});
});

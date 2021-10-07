const exec = require("child_process").exec;
const execFile = require("child_process").execFile;
const fs = require("fs");
const os = require("os");

const perf_dir = "./logs";

const OS_TO_NAME = {
	darwin: "macOS",
	win32: "Windows",
	linux: "Linux",
};

const build_dir = "./bin/" + OS_TO_NAME[os.platform()];

function execute(command, callback) {
	exec(command, function (err, stdout, stderr) {
		if (stderr) {
			console.log(stderr);
		}
		callback(stdout);
	});
}

function handle_perf(message) {
	if (!fs.existsSync(perf_dir)) {
		fs.mkdirSync(perf_dir);
	}

	fs.readdir(perf_dir, (_, files) => {
		var date = new Date();
		date = date.getMonth() + 1 + "/" + (date.getDate() > 9 ? "" : "0") + date.getDate() + "/" + date.getFullYear();

		message = "(" + date + ")\n" + message;

		var length = files.length + 1;
		var name = "0".repeat(4 - length.toString().length) + length;

		var file = perf_dir + "/Perf-" + name + ".txt";
		fs.writeFile(file, message, (err) => {
			if (err) throw err;
			console.log("Saved to " + file);
		});
	});
}

execute("lua Lua.lua --debug run test.lua", (message) => {
	handle_perf(message);
});

if (fs.existsSync(build_dir)) {
	execFile(build_dir + "/Lua.exe", ["--debug", "run", "test.lua"], {cwd: __dirname}, (err, stdout, stderr) => {
		if (err) {
			console.error(err);
		}
		if (stderr) {
			console.error(stderr);
		}

		stdout = "(THIS WAS A BUILD VERSION)\n" + stdout;
		handle_perf(stdout);
	});
}

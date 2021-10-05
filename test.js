const parser = require("luaparse");
const fs = require("fs");
const path = require("path");

const filepath = path.join(__dirname, "test.lua");

fs.readFile(filepath, {encoding: "utf-8"}, (err, data) => {
	if (err) {
		console.error(err);
		return;
	}

	console.log(data.length);
	const time = Date.now();
	var ast = parser.parse(data);
	console.log("Time: ", Date.now() - time + "ms");
});

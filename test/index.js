"use strict";
const assert = require("assert");
const exec = require("exec-extra");

describe("API", () => {
	it("install with cache", async () => {
		const stdout = await exec("./ci-npm-cache.sh", [
			"npm",
			"i",
		]);
		assert.ok(stdout);
	});
});

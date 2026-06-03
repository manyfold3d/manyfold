#!/usr/bin/env node

import * as esbuild from 'esbuild'

const config = {
	logLevel: "info",
	entryPoints: ["app/javascript/*.*"],
	minify: true,
	treeShaking: true,
	bundle: true,
	sourcemap: true,
	outdir: "app/assets/builds",
	publicPath: "assets",
}

const args = process.argv.slice(2);

if (args.includes("--watch")) {
	let ctx = await esbuild.context(config)
	await ctx.watch()
} else {
	esbuild.build(config).catch(() => process.exit(1));
}

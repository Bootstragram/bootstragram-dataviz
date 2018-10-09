build:
	rm -f lib/*
	yarn compile-coffee
	yarn compile-less
	yarn compile-sass

clean:
	# `git clean -xdf` is too dangerous as it removes all WIP files
	rm -rf lib node_modules

install:
	yarn install

docs-serve:
	cd docs && python -m SimpleHTTPServer

package:
	yarn rollup

release: clean install build package
	# Can't use `yarn publish` as it's not compatible with NPM's 2FA
	npm publish

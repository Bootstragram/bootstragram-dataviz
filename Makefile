build:
	rm -f lib/*
	yarn compile-coffee
	yarn compile-less

clean:
	# `git clean -xdf` is too dangerous as it removes all WIP files
	rm -rf lib node_modules

install:
	yarn install

docs-serve:
	cd docs && python -m SimpleHTTPServer

package:
	yarn rollup

build:
	rm -f lib/*
	yarn compile-coffee
	yarn compile-less

install:
	yarn install

docs-serve:
	cd docs && python -m SimpleHTTPServer

build:
	rm -f lib/*
	yarn compile-coffee
	yarn compile-less

clean:
	git clean -xdf

install:
	yarn install

docs-serve:
	cd docs && python -m SimpleHTTPServer

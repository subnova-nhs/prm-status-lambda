.PHONY : build clean test funtest	

account_id := $(shell aws sts get-caller-identity |  jq -r .Account)

source = main.js constants.js

build : lambda.zip

lambda.zip : prod_dep/node_modules $(source)
	zip -u lambda.zip $(source) || true
	cd prod_dep && zip -u ../lambda.zip node_modules -r || true

node_modules package-lock.json : package.json
	npm install

prod_dep/node_modules : package.json
	mkdir -p prod_dep
	cp -p package.json package-lock.json prod_dep
	cd prod_dep && npm install --production

test : node_modules *.js
	npm test

terratest : lambda.zip
	$(MAKE) -C ../../deploy/test/status_lambda

clean :
	rm -rf node_modules prod_dep lambda.zip

deploy-% : build test
	$(MAKE) -C ../../deploy/$*-$(account_id)/status_lambda apply

update-% : build test
	$(MAKE) -C ../../deploy/$*-$(account_id)/status_lambda update
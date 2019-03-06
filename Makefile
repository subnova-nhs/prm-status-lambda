test :
	$(MAKE) -C lambda/status test

build :
	$(MAKE) -C lambda/status build

terratest : build
	$(MAKE) -C deploy/test/status_lambda

deploy-% : build
	$(MAKE) -C deploy/$*/status_lambda
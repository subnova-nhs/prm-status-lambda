.PHONY : test clean

test : vendor *.go
	go test

vendor : Gopkg.toml
	dep ensure

clean :
	go clean
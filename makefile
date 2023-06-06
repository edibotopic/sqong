all: clean build

build:
	@echo "Built game in bin directory"
	@mkdir bin && odin build . -o:speed -out:bin/sqong

clean:
	@echo "Cleaned bin directory"
	@if [ ./bin/ ]; then \
		rm -rf ./bin/; \
	fi

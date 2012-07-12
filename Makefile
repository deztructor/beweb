all : src tests

src :
	cd src && make

tests :
	cd tests && make

.PHONY : all src tests

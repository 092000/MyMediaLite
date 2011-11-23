PDF_VIEWER=evince
EDITOR=editor
GENDARME_OPTIONS=--quiet --severity critical+
SRC_DIR=src
PREFIX=/usr/local
VERSION=2.02
HTML_MDOC_DIR=website/public_html/documentation/mdoc
HTML_DOXYGEN_DIR=website/public_html/documentation/doxygen
MYMEDIA_ASSEMBLY_DIR=$(CURDIR)/src/MyMediaLite/bin/Debug
ITEM_REC_DIR=${SRC_DIR}/Programs/ItemRecommendation
RATING_PRED_DIR=${SRC_DIR}/Programs/RatingPrediction
export IRONPYTHONPATH := ${MYMEDIA_ASSEMBLY_DIR}

.PHONY: clean veryclean mymedialite install uninstall todo gendarme monodoc mdoc-html view-mdoc-html doxygen view-doxygen flyer edit-flyer website copy-website binary-package source-package test release download-movielens copy-packages-website example-python example-ruby check-for-unnecessary-type-declarations
all: mymedialite

mymedialite:
	cd ${SRC_DIR} && make all

clean:
	cd ${SRC_DIR} && make clean
	cd examples/csharp && make clean
	rm -rf ${SRC_DIR}/Programs/*/bin/Debug/*
	rm -rf ${SRC_DIR}/Programs/*/bin/Release/*
	rm -rf ${SRC_DIR}/KDDCup2011/*/bin/Debug/*
	rm -rf ${SRC_DIR}/KDDCup2011/*/bin/Release/*
	rm -rf ${SRC_DIR}/Mapping/*/bin/Debug/*
	rm -rf ${SRC_DIR}/Mapping/*/bin/Release/*
	rm -rf ${SRC_DIR}/*/bin/Debug/*
	rm -rf ${SRC_DIR}/*/bin/Release/*
	rm -rf ${SRC_DIR}/RatingService/bin/*
	rm -rf ${SRC_DIR}/test-results
	rm -rf ${SRC_DIR}/*/*.tar.gz
	rm -rf ${SRC_DIR}/*/*.pidb
	rm -rf doc/monodoc/*
	rm -rf lib/mymedialite/*
	rm -rf MyMediaLite-*/

veryclean: clean
	rm -f *.tar.gz
	rm -rf doc/doxygen/*
	rm -rf website/public_html/*

install:
	cd ${SRC_DIR} && make install PREFIX=${PREFIX}

uninstall:
	cd ${SRC_DIR} && make uninstall

binary-package:
	mkdir MyMediaLite-${VERSION}
	mkdir MyMediaLite-${VERSION}/doc
	cp doc/Authors doc/Changes doc/ComponentLicenses doc/GPL-3 doc/Installation doc/TODO MyMediaLite-${VERSION}/doc
	mkdir MyMediaLite-${VERSION}/doc/api
	cp -r doc/doxygen/html MyMediaLite-${VERSION}/doc/api
	cp -r examples scripts MyMediaLite-${VERSION}
	cp README MyMediaLite-${VERSION}
	cp ${ITEM_REC_DIR}/bin/Debug/*.exe MyMediaLite-${VERSION}
	cp ${ITEM_REC_DIR}/bin/Debug/*.dll MyMediaLite-${VERSION}
	cp ${ITEM_REC_DIR}/bin/Debug/*.mdb MyMediaLite-${VERSION}
	cp ${RATING_PRED_DIR}/bin/Debug/*.exe MyMediaLite-${VERSION}
	cp ${RATING_PRED_DIR}/bin/Debug/*.exe.mdb MyMediaLite-${VERSION}
	tar -cvzf MyMediaLite-${VERSION}.tar.gz MyMediaLite-${VERSION}
	rm -rf MyMediaLite-${VERSION}

source-package: clean
	mkdir MyMediaLite-${VERSION}.src
	mkdir MyMediaLite-${VERSION}.src/doc
	cp doc/Authors doc/Changes doc/CodingStandards doc/ComponentLicenses doc/GPL-3 doc/Installation doc/ReleaseChecklist doc/TODO MyMediaLite-${VERSION}.src/doc
	mkdir MyMediaLite-${VERSION}.src/doc/api
	cp -r doc/doxygen/html MyMediaLite-${VERSION}.src/doc/api
	cp -r src examples scripts tests lib MyMediaLite-${VERSION}.src
	cp Makefile README MyMediaLite-${VERSION}.src
	mkdir MyMediaLite-${VERSION}.src/data
	tar -cvzf MyMediaLite-${VERSION}.src.tar.gz MyMediaLite-${VERSION}.src
	rm -rf MyMediaLite-${VERSION}.src

#test: all
test: data/ml-100k/u.data
	time tests/test_rating_prediction.sh
	time tests/test_item_recommendation.sh
	time tests/test_load_save.sh
	time tests/test_cv.sh
	time tests/test_random_split.sh
	time tests/test_rating_prediction_online.sh

release: binary-package source-package
	head doc/Changes
	git status
	cp doc/Changes website/src/download
	cat doc/ReleaseChecklist

example-csharp: data/ml-100k/u.data
	cd examples/csharp && make
	cd examples/csharp && make run

example-fsharp: data/ml-100k/u.data
	cd examples/fsharp && make
	cd data/ml-100k && mono ../../examples/fsharp/rating_prediction.exe
	cd data/ml-100k && mono ../../examples/fsharp/item_recommendation.exe


example-python: data/ml-100k/u.data
	cd data/ml-100k && ipy ../../examples/python/rating_prediction.py
	cd data/ml-100k && ipy ../../examples/python/item_recommendation.py

example-ruby: data/ml-100k/u.data
	cd data/ml-100k && ir -I${MYMEDIA_ASSEMBLY_DIR} ../../examples/ruby/rating_prediction.rb
	cd data/ml-100k && ir -I${MYMEDIA_ASSEMBLY_DIR} ../../examples/ruby/item_recommendation.rb

data:
	mkdir data/

data/ml-100k/u.data:
	scripts/download_movielens.sh

download-movielens: data
	scripts/download_movielens.sh

download-imdb: data
	scripts/download_imdb.sh

todo:
	ack --type=csharp TODO                    ${SRC_DIR}; echo
	ack --type=csharp FIXME                   ${SRC_DIR}; echo
	ack --type=csharp HACK                    ${SRC_DIR}; echo
	ack --type=csharp NotImplementedException ${SRC_DIR}; echo
	ack --type=csharp TODO                    ${SRC_DIR} | wc -l
	ack --type=csharp FIXME                   ${SRC_DIR} | wc -l
	ack --type=csharp HACK                    ${SRC_DIR} | wc -l
	ack --type=csharp NotImplementedException ${SRC_DIR} | wc -l

## TODO create regex with less false positives
check-for-unnecessary-type-declarations:
	ack --type=csharp "new" src/MyMediaLite | grep -v static | grep -v var | grep -v public | grep -v private | grep -v protected | grep -v return | grep -v throw | grep -v this | grep -v //

gendarme:
	gendarme ${GENDARME_OPTIONS} $RATING_PRED_DIR//bin/Debug/*.exe
	gendarme ${GENDARME_OPTIONS} $ITEM_REC_DIR/bin/Debug/*.exe
	gendarme ${GENDARME_OPTIONS} ${SRC_DIR}/Mapping/MappingRatingPrediction/bin/Debug/*.exe
	gendarme ${GENDARME_OPTIONS} ${SRC_DIR}/Mapping/MappingItemPrediction/bin/Debug/*.exe
	gendarme ${GENDARME_OPTIONS} ${SRC_DIR}/MyMediaLite/bin/Debug/MyMediaLite.dll
	gendarme ${GENDARME_OPTIONS} ${SRC_DIR}/MyMediaLiteExperimental/bin/Debug/MyMediaLiteExperimental.dll
	gendarme ${GENDARME_OPTIONS} ${SRC_DIR}/MyMediaLiteExperimental/bin/Debug/SVM.dll

apidoc: mdoc-html doxygen

monodoc:
	mdoc update -i ${SRC_DIR}/MyMediaLite/bin/Debug/MyMediaLite.xml -o doc/monodoc/ ${SRC_DIR}/MyMediaLite/bin/Debug/MyMediaLite.dll

mdoc-html: monodoc
	mdoc-export-html doc/monodoc/ -o ${HTML_MDOC_DIR} --template=doc/htmldoc-template.xsl
	perl -e "use File::Slurp; \$$f = read_file '${HTML_MDOC_DIR}/index.html'; \$$f =~ s/\n.+?\n.+?experimental.+?\n.+?\n.+?\n.+?\n.+//; print \$$f;" > tmp.html && cat tmp.html > ${HTML_MDOC_DIR}/index.html && rm tmp.html

view-mdoc:
	x-www-browser file://${HTML_MDOC_DIR}/index.html

doxygen:
	cd doc/ && doxygen
	mkdir -p ${HTML_DOXYGEN_DIR}
	cp -r doc/doxygen/html/* ${HTML_DOXYGEN_DIR}

view-doxygen:
	x-www-browser file://${HTML_DOXYGEN_DIR}/index.html

flyer:
	cd doc/flyer; pdflatex mymedialite-flyer.tex

edit-flyer:
	${EDITOR} doc/flyer/mymedialite-flyer.tex

view-flyer:
	${PDF_VIEWER} doc/flyer/mymedialite-flyer.pdf &

website:
	ttree -s website/src/ -d website/public_html/ -c website/lib/ -l website/lib/ -r -f config --post_chomp -a

copy-website: website
	cp -r website/public_html/* ${HOME}/homepage/public_html/mymedialite/

copy-packages-website:
	cp MyMediaLite-${VERSION}.tar.gz MyMediaLite-${VERSION}.src.tar.gz ${HOME}/homepage/public_html/mymedialite/download

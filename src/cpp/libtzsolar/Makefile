SUBDIRS = libtzsolar libtzsolar-boost tests
.PHONY: all test clean $(SUBDIRS)

all: subdirs

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

test: tests

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

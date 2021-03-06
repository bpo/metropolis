# use GNU Make to run tests in parallel, and without depending on RubyGems
all::
RUBY = ruby
RAKE = rake
RSYNC = rsync

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@./GIT-VERSION-GEN
-include GIT-VERSION-FILE
-include local.mk
ifeq ($(RUBY_VERSION),)
  RUBY_VERSION := $(shell $(RUBY) -e 'puts RUBY_VERSION')
endif

install: $(bins)
	$(prep_setup_rb)
	$(RM) -r .install-tmp
	mkdir .install-tmp
	cp -p bin/* .install-tmp
	$(RUBY) setup.rb all
	$(RM) $^
	mv .install-tmp/* bin/
	$(RM) -r .install-tmp
	$(prep_setup_rb)

setup_rb_files := .config InstalledFiles
prep_setup_rb := @-$(RM) $(setup_rb_files);$(MAKE) -C $(ext) clean

clean:
	$(RM) $(setup_rb_files)

pkg_extra := GIT-VERSION-FILE NEWS ChangeLog LATEST
manifest:
	$(RM) .manifest
	$(MAKE) .manifest

.manifest:
	wrongdoc prepare
	(git ls-files && for i in $@ $(pkg_extra);do echo $$i; done) | \
	  LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@
	$(RM) $@+

doc: .document .wrongdoc.yml
	wrongdoc all
	install -m644 COPYING doc/COPYING
	install -m644 $(shell grep '^[A-Z]' .document) doc/

ifneq ($(VERSION),)
rfproject := rainbows
rfpackage := metropolis
pkggem := pkg/$(rfpackage)-$(VERSION).gem
pkgtgz := pkg/$(rfpackage)-$(VERSION).tgz
release_notes := release_notes-$(VERSION)
release_changes := release_changes-$(VERSION)

release-notes: $(release_notes)
release-changes: $(release_changes)
$(release_changes):
	wrongdoc release_changes > $@+
	$(VISUAL) $@+ && test -s $@+ && mv $@+ $@
$(release_notes):
	wrongdoc release_notes > $@+
	$(VISUAL) $@+ && test -s $@+ && mv $@+ $@

# ensures we're actually on the tagged $(VERSION), only used for release
verify:
	test x"$(shell umask)" = x0022
	git rev-parse --verify refs/tags/v$(VERSION)^{}
	git diff-index --quiet HEAD^0
	test `git rev-parse --verify HEAD^0` = \
	     `git rev-parse --verify refs/tags/v$(VERSION)^{}`

fix-perms:
	-git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	-git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755

gem: $(pkggem)

install-gem: $(pkggem)
	gem install $(CURDIR)/$<

$(pkggem): manifest fix-perms
	gem build $(rfpackage).gemspec
	mkdir -p pkg
	mv $(@F) $@

$(pkgtgz): distdir = $(basename $@)
$(pkgtgz): HEAD = v$(VERSION)
$(pkgtgz): manifest fix-perms
	@test -n "$(distdir)"
	$(RM) -r $(distdir)
	mkdir -p $(distdir)
	tar cf - `cat .manifest` | (cd $(distdir) && tar x)
	cd pkg && tar cf - $(basename $(@F)) | gzip -9 > $(@F)+
	mv $@+ $@

package: $(pkgtgz) $(pkggem)

test-release: verify package $(release_notes) $(release_changes)
release: verify package $(release_notes) $(release_changes)
	# make tgz release on RubyForge
	rubyforge add_release -f -n $(release_notes) -a $(release_changes) \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkgtgz)
	# push gem to RubyGems.org
	gem push $(pkggem)
	# in case of gem downloads from RubyForge releases page
	-rubyforge add_file \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkggem)
else
gem install-gem: GIT-VERSION-FILE
	$(MAKE) $@ VERSION=$(GIT_VERSION)
endif

all:: test

test_units := $(wildcard test/test_*.rb)
test: test-unit
test-unit: $(test_units)
$(test_units):
	$(RUBY) -I lib $@

# this requires GNU coreutils variants
publish_doc:
	-git set-file-times
	$(RM) -r doc
	$(MAKE) doc
	find doc/images -type f | \
		TZ=UTC xargs touch -d '1970-01-01 00:00:02' doc/rdoc.css
	$(MAKE) doc_gz
	chmod 644 $$(find doc -type f)
	$(RSYNC) -av doc/ metropolis.bogomips.org:/srv/metropolis/
	git ls-files | xargs touch

# Create gzip variants of the same timestamp as the original so nginx
# "gzip_static on" can serve the gzipped versions directly.
doc_gz: docs = $(shell find doc -type f ! -regex '^.*\.\(gif\|jpg\|png\|gz\)$$')
doc_gz:
	for i in $(docs); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done

.PHONY: .FORCE-GIT-VERSION-FILE doc manifest man test $(test_units)

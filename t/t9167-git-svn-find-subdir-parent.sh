#!/bin/sh
#
# Copyright (c) 2006 Eric Wong
#

TEST_NO_CREATE_REPO=x
test_description='git svn find subdir parent'
. ./lib-git-svn.sh

svnrepo_basename=`basename "$rawsvnrepo"`
svnrepo_dirname=`dirname "$rawsvnrepo"`

initcmd='
	mkdir import &&
	(
		cd import &&
		mkdir -p trunk/module tags &&
		echo hello >trunk/module/readme &&
		svn_cmd import -m "initial" . "$svnrepo"
	) &&
	svn_cmd co "$svnrepo" t &&
	(
		cd t &&

		for n in 2 3 4; do
			echo "revision $n" >trunk/module/readme &&
			svn_cmd commit -m"revision $n"
		done &&
		(
			cd .. &&
			cp -a t m &&
			cd "$svnrepo_dirname" &&
			cp -a "$svnrepo_basename" m.svn &&
			mv "$svnrepo_basename" t.svn &&
			ln -s t.svn "$svnrepo_basename"
		) &&

		svn_cmd cp -m"create tag 1.0" "$svnrepo/trunk/" "$svnrepo/tags/1.0" &&

		for n in 6 7 8; do
			echo "revision $n" >trunk/module/readme &&
			svn_cmd commit -m"revision $n"
		done &&
		svn_cmd cp -m"create tag 1.1" "$svnrepo/trunk/" "$svnrepo/tags/1.1" &&

		(
			cd "$svnrepo_dirname" &&
			rm "$svnrepo_basename" &&
			ln -s m.svn "$svnrepo_basename"
		) &&

		cd ../m &&

		svn_cmd cp -m"create tag 1.0" "$svnrepo/trunk/module" "$svnrepo/tags/1.0" &&

		for n in 6 7 8; do
			echo "revision $n" >trunk/module/readme &&
			svn_cmd commit -m"revision $n"
		done &&
		svn_cmd cp -m"create tag 1.1" "$svnrepo/trunk/module" "$svnrepo/tags/1.1"
	)
	'

set -- `printf %s %s "$initcmd" "$svnrepo_basename" | cksum`

svnrepo_bak=/tmp/test-svn-repo-$1.tar

if [ -e "$svnrepo_bak" ]; then
	( cd "$svnrepo_dirname" && tar -xf "$svnrepo_bak" && rm -rf "$svnrepo_basename" && ln -s m.svn "$svnrepo_basename" )
else
	test_expect_success 'initialize repo' "$initcmd"
	( cd "$svnrepo_dirname" && tar -cf "$svnrepo_bak" t.svn m.svn )
fi

test_expect_success 'init and fetch a moved directory m' '
	git svn clone --stdlayout --revision=0:5 "$svnrepo" gitrepo 2>&1 | tee calls.m &&
	( cd gitrepo &&
	git svn fetch 2>&1 | tee ../calls2.m
	)
'

test_expect_success 'init and fetch a moved directory t' '
	( cd "$svnrepo_dirname" && rm "$svnrepo_basename" && ln -s t.svn "$svnrepo_basename" ) &&
	rm -rf gitrepo &&
	git svn clone --stdlayout --revision=0:5 "$svnrepo" gitrepo 2>&1 | tee calls.t &&
	( cd gitrepo &&
	git svn fetch 2>&1 | tee ../calls2.t
	)
'

exit 1

test_done

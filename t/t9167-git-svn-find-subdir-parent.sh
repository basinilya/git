#!/bin/sh
#
# Copyright (c) 2006 Eric Wong
#

TEST_NO_CREATE_REPO=x
test_description='git svn find subdir parent'
. ./lib-git-svn.sh

GIT_REPO=git-svn-repo

copysubdir=module
#copysubdir=

initcmd='
	mkdir import &&
	(
		cd import &&
		mkdir -p trunk/module tags &&
		echo hello >trunk/module/readme &&
		svn_cmd import -m "initial" . "$svnrepo"
	) &&
	svn_cmd co "$svnrepo" wc &&
	(
		cd wc &&

		for n in 2 3 4; do
			echo "revision $n" >trunk/module/readme &&
			svn_cmd commit -m"revision $n"
		done &&
		svn_cmd cp -m"create tag 1.0" "$svnrepo/trunk/$copysubdir" "$svnrepo/tags/${copysubdir}_1.0" &&

		for n in 6 7 8; do
			echo "revision $n" >trunk/module/readme &&
			svn_cmd commit -m"revision $n"
		done &&
		svn_cmd cp -m"create tag 1.1" "$svnrepo/trunk/$copysubdir" "$svnrepo/tags/${copysubdir}_1.1" &&

		true
	)
	'

svnrepo_basename=`basename "$rawsvnrepo"`
svnrepo_dirname=`dirname "$rawsvnrepo"`

set -- `printf %s %s %s "$initcmd" "$copysubdir" "$svnrepo_basename" | cksum`

svnrepo_bak=/tmp/test-svn-repo-$1.tar

if [ -e "$svnrepo_bak" ]; then
	( cd "$svnrepo_dirname" && rm -rf "$svnrepo_basename" && tar -xf "$svnrepo_bak" )
else
	test_expect_success 'initialize repo' "$initcmd"
	( cd "$svnrepo_dirname" && tar -cf "$svnrepo_bak" "$svnrepo_basename" )
fi

test_expect_success 'init and fetch a moved directory' '
	git svn clone --stdlayout "$svnrepo" "$GIT_REPO"
'

test_done

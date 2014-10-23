#!/bin/bash

DOMAIN=$1
DATABASE=$DOMAIN.log
g_urls=
# 将制定页面中本站的链接找出来并返回
function spider_page() {
	thiz=`curl $1 2>/dev/null|grep -o "href=[\'\"]http://[^\"\'\?\#]\+[\"]"|grep -o "http://[^\"]\+"|uniq 2>/dev/null`
	g_urls="";
	for u in $thiz; do
		grep $u $DATABASE >/dev/null 2>&1
		if [ $? == 0 ]; then
		#	echo exist URL: $u
			continue; 
		fi
		#echo $u | grep $DOMAIN >/dev/null 2>&1
		#if [ $? != 0 ]; then 
		#	echo not domain URL: $u
		#	continue; 
		#fi
		g_urls="$g_urls $u";
		echo $u >> $DATABASE
		echo "   new url: $u"
	done
}

function spider_enum() {
	for u in $@; do
		if [ ${#u} == 0 ];then continue; fi
		echo spidering on page: $u
		spider_page $u
		newurls="$newurls $g_urls"
	done
	spider_enum $newurls
}

spider_page $DOMAIN
urls=$g_urls
#echo $urls
for u in $urls; do
	#echo $u | grep $DOMAIN > /dev/null 2>&1
	#if [ $? != 0 ]; then continue; fi
	echo $u >> $DATABASE
	echo "   new url: $u"
done

spider_enum $urls
echo "done"
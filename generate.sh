#!/bin/bash

#set -euo pipefail

TOP=$(pwd)
TMPDIR="$(pwd)/tmp"
MANIFESTS="manifests"

download_mixin() {
	local mixin="$1"
	local repo="$2"
	local subdir="$3"
	
	cd "$TMPDIR"
	git clone --depth 1 --filter=blob:none "$repo" "$mixin"
	cd "$mixin/$subdir"
	if [ -f "jsonnetfile.json" ]; then
		jb install
	fi
	
	mkdir -p $TOP/$MANIFESTS/$mixin/dashboards
	jsonnet -J vendor -S -e 'std.manifestYamlDoc((import "mixin.libsonnet").prometheusAlerts)' | gojsontoyaml > $TOP/$MANIFESTS/$mixin/alerts.yaml || :
	jsonnet -J vendor -S -e 'std.manifestYamlDoc((import "mixin.libsonnet").prometheusRules)' | gojsontoyaml > $TOP/$MANIFESTS/$mixin/rules.yaml || :
	jsonnet -J vendor -m $TOP/$MANIFESTS/$mixin/dashboards -e '(import "mixin.libsonnet").grafanaDashboards' || :
}

# Prepare env
rm -rf $MANIFESTS $TMPDIR
mkdir -p $TMPDIR

# Generate manifests
cat mixins.yaml | gojsontoyaml -yamltojson > $TMPDIR/mixins.json

for mixin in $(cat $TMPDIR/mixins.json | jq -r '.mixins[].name'); do
	repo="$(cat $TMPDIR/mixins.json | jq -r ".mixins[] | select(.name == \"$mixin\") | .source")"
	subdir="$(cat $TMPDIR/mixins.json | jq -r ".mixins[] | select(.name == \"$mixin\") | .subdir")"
	set +u
	download_mixin $mixin $repo $subdir
	#set -u
done

# Remove previously generated site
cd $TOP
rm -rf site/content/*

# Create top-level index.md header
INDEXFILE="site/content/_index.md"
touch $INDEXFILE
cat <<EOF > $INDEXFILE
---
title: Generated monitoring mixins
---

EOF

# Create index.md files for each mixin and add it to global index.md
for dir in ${MANIFESTS}/*; do
	mixin=$(basename $dir)
	mkdir -p "site/content/${mixin}"
	file="site/content/${mixin}/index.md"
	# Create header
	cat << EOF > $file
---
title: $mixin
---

EOF
	if [ -s "$dir/alerts.yaml" ]; then
		echo -e "# Alerts\n\n[embedmd]:# (../../../$MANIFESTS/$mixin/alerts.yaml yaml)\n" >> $file
	fi
	if [ -s "$dir/rules.yaml" ]; then
		echo -e "# Recording rules\n\n[embedmd]:# (../../../$MANIFESTS/$mixin/rules.yaml yaml)\n" >> $file
	fi
	if [ -s "$dir/dashboards.yaml" ]; then
		echo -e "# Dashboards\n\n[embedmd]:# (../../../$MANIFESTS/$mixin/dashboards.yaml yaml)\n" >> $file
	fi
	name=${mixin%.*}

	echo -e "\n## $name\n" >> $INDEXFILE
	if [ -s "$dir/alerts.yaml" ]; then
		echo "- [Alerts](/$name#alerts)" >> $INDEXFILE
	fi
	if [ -s "$dir/rules.yaml" ]; then
		echo "- [Recording Rules](/$name#rules)" >> $INDEXFILE
	fi
	if [ -s "$dir/dashboards.yaml" ]; then
		echo "- [Dashboards](/$name#dashboards)" >> $INDEXFILE
	fi
done

# Embed alerts and rules into site files
embedmd -w $(find site/content/ -name "*.md")

#!/bin/bash

#set -euo pipefail

TOP=$(pwd)
TMPDIR="$(pwd)/tmp"
MANIFESTS="manifests"

download_mixin() {
	local mixin="$1"
	local repo="$2"
	local subdir="$3"
	local curdir=$(pwd)
	
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
	cd "$curdir"
}

# Prepare env
rm -rf site/content/* $MANIFESTS $TMPDIR
mkdir -p $TMPDIR

# Create top-level index.md header
INDEXFILE="site/content/_index.md"
touch $INDEXFILE
cat <<EOF > $INDEXFILE
---
title: Prometheus monitoring mixins
---

EOF

# Generate manifests
cat mixins.yaml | gojsontoyaml -yamltojson > $TMPDIR/mixins.json

for mixin in $(cat $TMPDIR/mixins.json | jq -r '.mixins[].name'); do
	cd $TOP
	repo="$(cat $TMPDIR/mixins.json | jq -r ".mixins[] | select(.name == \"$mixin\") | .source")"
	subdir="$(cat $TMPDIR/mixins.json | jq -r ".mixins[] | select(.name == \"$mixin\") | .subdir")"
	text="$(cat $TMPDIR/mixins.json | jq -r ".mixins[] | select(.name == \"$mixin\") | .text")"
	if [ "$text" == "null" ]; then text=""; fi
	set +u
	download_mixin $mixin $repo $subdir
	#set -u

	mkdir -p "site/content/${mixin}"
	file="site/content/${mixin}/index.md"
	# Create header
	if [ -n "$subdir" ]; then
		location="$repo/tree/master/$subdir"
	else
		location="$repo"
	fi
	cat << EOF > $file
---
title: $mixin
---

$text

Mixin available at [${repo#*//}]($location)

EOF
	echo -e "\n## $mixin\n" >> $INDEXFILE
	
	dir="$TOP/$MANIFESTS/$mixin"
	if [ -s "$dir/alerts.yaml" ] && [ "$(stat -c%s "$dir/alerts.yaml")" -gt 20 ]; then
		echo -e "# Alerts\n\n[embedmd]:# (../../../$MANIFESTS/$mixin/alerts.yaml yaml)\n" >> $file
		echo "- [Alerts](/$mixin#alerts)" >> $INDEXFILE
	fi
	if [ -s "$dir/rules.yaml" ] && [ "$(stat -c%s "$dir/rules.yaml")" -gt 20 ]; then
		echo -e "# Recording rules\n\n[embedmd]:# (../../../$MANIFESTS/$mixin/rules.yaml yaml)\n" >> $file
		echo "- [Recording Rules](/$mixin#recording-rules)" >> $INDEXFILE
	fi
	if [ "$(ls -A "$dir/dashboards")" ]; then
		echo -e "# Dashboards\nFollowing dashboards are generated from mixins and hosted on github:\n\n" >> $file
		for dashboard in $dir/dashboards/*.json; do
			d=$(basename $dashboard)
			echo "- [${d%.*}](https://github.com/cloudalchemy/mixins/blob/master/manifests/$mixin/dashboards/$d)" >> $file
		done
		echo "- [Dashboards](/$mixin#dashboards)" >> $INDEXFILE
	fi
done

# Embed alerts and rules into site files
embedmd -w $(find site/content/ -name "*.md")

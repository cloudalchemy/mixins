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

parse_rules() {
	local source="$1"
	local type="$2"
	for group in $(echo "$source" | jq -cr '.groups[].name'); do
		echo -e "### ${group}\n"
		for rule in $(echo "$source" | jq -cr ".groups[] | select(.name == \"${group}\") | .rules[] | @base64"); do
			var=$(echo "$rule" | base64 --decode | gojsontoyaml);
			name=$(echo -e "$var" | grep "$type" | awk -F ': ' '{print $2}')
			echo -e "##### ${name}\n"
			echo -e '{{< code lang="yaml" >}}'
			echo -e "$var"
			echo -e '{{< /code >}}\n '
		done
	done
}

mixin_header() {
	local name="$1"
	local repo="$2"
	local url="$3"
	local description="$4"

	cat << EOF
---
title: $name
---

## Overview

$description

{{< panel style="primary" title="Jsonnet source" >}}
Mixin jsonnet code is available at [${repo#*//}]($url)
{{< /panel >}}

EOF
}

# remove generated manifests and temporary directory
rm -rf $MANIFESTS $TMPDIR
# remove generated site content
find site/content/ ! -name '_index.md' -type f -exec rm -rf {} +
mkdir -p $TMPDIR

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
	file="site/content/${mixin}/_index.md"
	# Create header
	if [ -n "$subdir" ]; then
		location="$repo/tree/master/$subdir"
	else
		location="$repo"
	fi
	mixin_header "$mixin" "$repo" "$location" "$text" > "$file"

	dir="$TOP/$MANIFESTS/$mixin"
	# Alerts
	if [ -s "$dir/alerts.yaml" ] && [ "$(stat -c%s "$dir/alerts.yaml")" -gt 20 ]; then
		echo -e "## Alerts\n" >> $file
		echo -e '{{< panel style="info" >}}' >> $file
		echo -e "Complete list of pregenerated alerts is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/$mixin/alerts.yaml)." >> $file
		echo -e '{{< /panel >}}\n' >> $file

		parse_rules "$(gojsontoyaml -yamltojson < "$dir/alerts.yaml")" "alert" >> "$file"
	fi

	# Recording Rules
	if [ -s "$dir/rules.yaml" ] && [ "$(stat -c%s "$dir/rules.yaml")" -gt 20 ]; then
		echo -e "## Recording rules\n" >> $file
		echo -e '{{< panel style="info" >}}' >> $file
		echo -e "Complete list of pregenerated recording rules is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/$mixin/rules.yaml)." >> $file
		echo -e '{{< /panel >}}\n' >> $file

		parse_rules "$(gojsontoyaml -yamltojson < "$dir/rules.yaml")" "record" >> "$file"
	fi

	# Dashboards
	if [ "$(ls -A "$dir/dashboards")" ]; then
		echo -e "## Dashboards\nFollowing dashboards are generated from mixins and hosted on github:\n\n" >> $file
		for dashboard in $dir/dashboards/*.json; do
			d=$(basename $dashboard)
			echo "- [${d%.*}](https://github.com/cloudalchemy/mixins/blob/master/manifests/$mixin/dashboards/$d)" >> $file
		done
	fi
done

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
	cat << EOF > $file
---
title: $mixin
---

$text

{{< panel style="primary" title="Jsonnet source" >}}
Mixin jsonnet code is available at [${repo#*//}]($location)
{{< /panel >}}

EOF
	dir="$TOP/$MANIFESTS/$mixin"
	# Alerts
	if [ -s "$dir/alerts.yaml" ] && [ "$(stat -c%s "$dir/alerts.yaml")" -gt 20 ]; then
		echo -e "## Alerts\n" >> $file
		echo -e '{{< panel style="info" >}}' >> $file
		echo -e "Complete list of pregenerated alerts is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/$mixin/alerts.yaml)." >> $file
		echo -e '{{< /panel >}}\n' >> $file

		for i in $(cat $dir/alerts.yaml | gojsontoyaml -yamltojson | jq -cr '[.groups[].rules] | flatten | .[] | @base64'); do
			var=$(echo "$i" | base64 --decode | gojsontoyaml);
			name=$(echo -e "$var" | grep 'alert' | awk -F ': ' '{print $2}')
			echo -e "### ${name}\n" >> $file
			echo -e '{{< code lang="yaml" >}}' >> $file
			echo -e "$var" >> $file
			echo -e '{{< /code >}}\n ' >> $file
		done
	fi

	# Recording Rules
	if [ -s "$dir/rules.yaml" ] && [ "$(stat -c%s "$dir/rules.yaml")" -gt 20 ]; then
		echo -e "## Recording rules\n" >> $file
		echo -e '{{< panel style="info" >}}' >> $file
		echo -e "Complete list of pregenerated recording rules is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/$mixin/rules.yaml)." >> $file
		echo -e '{{< /panel >}}\n' >> $file
		
		for i in $(cat $dir/rules.yaml | gojsontoyaml -yamltojson | jq -cr '[.groups[].rules] | flatten | .[] | @base64'); do
			var=$(echo "$i" | base64 --decode | gojsontoyaml);
			name=$(echo -e "$var" | grep 'record' | awk -F ': ' '{print $2}')
			echo -e "### ${name}\n" >> $file
			echo -e '{{< code lang="yaml" >}}' >> $file
			echo -e "$var" >> $file
			echo -e '{{< /code >}}\n ' >> $file
		done
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

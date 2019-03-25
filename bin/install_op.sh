if [ $# -eq 0 ] && [ -f /usr/local/bin/op ]; then
	exit 1
fi

if [ "$(uname -s)" = "Darwin" ]; then
	curl -o /tmp/op.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_darwin_amd64_v0.5.5.zip
else
	curl -o /tmp/op.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_linux_amd64_v0.5.5.zip
fi
unzip /tmp/op.zip -d /tmp
mv /tmp/op /usr/local/bin

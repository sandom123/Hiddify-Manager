source /opt/hiddify-manager/common/utils.sh

# In docker apply paths install.sh may be skipped, so ensure required binaries exist.
if ! command -v obfs-server >/dev/null 2>&1 || ! command -v ss-server >/dev/null 2>&1; then
	install_package shadowsocks-libev simple-obfs
fi

systemctl enable hiddify-ss-faketls.service
systemctl restart hiddify-ss-faketls.service

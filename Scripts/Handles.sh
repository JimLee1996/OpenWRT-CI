#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"
cd $PKG_PATH

#修复HomeProxy的google检测
if [ -d *"homeproxy"* ]; then
	HP_PATH="homeproxy/root/usr/share/rpcd/ucode/luci.homeproxy"
	sed -i 's|www.google.com|www.google.com/generate_204|g' $HP_PATH

	cd $PKG_PATH && echo "homeproxy check has been fixed!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	cd ./luci-theme-argon/

	sed -i '/font-weight:/ {/!important/! s/\(font-weight:\s*\)[^;]*;/\1normal;/}' $(find ./luci-theme-argon -type f -iname "*.css")
	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#移除Shadowsocks组件
PW_FILE=$(find ./ -maxdepth 3 -type f -wholename "*/luci-app-passwall/Makefile")
if [ -f "$PW_FILE" ]; then
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Libev/,/x86_64/d' $PW_FILE
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR/,/default n/d' $PW_FILE
	sed -i '/Shadowsocks_NONE/d; /Shadowsocks_Libev/d; /ShadowsocksR/d' $PW_FILE

	cd $PKG_PATH && echo "passwall has been fixed!"
fi

SP_FILE=$(find ./ -maxdepth 3 -type f -wholename "*/luci-app-ssr-plus/Makefile")
if [ -f "$SP_FILE" ]; then
	sed -i '/default PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Libev/,/libev/d' $SP_FILE
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR/,/x86_64/d' $SP_FILE
	sed -i '/Shadowsocks_NONE/d; /Shadowsocks_Libev/d; /ShadowsocksR/d' $SP_FILE

	cd $PKG_PATH && echo "ssr-plus has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Frpc配置文件
FRPC_DIR=$(find ../feeds/luci/ -maxdepth 3 -type d -wholename "*/applications/luci-app-frpc")
if [ -d "$FRPC_DIR" ]; then
	FRPC_PATH="$FRPC_DIR/htdocs/luci-static/resources/view/frpc.js"
	sed -i 's|['tcp', 'kcp', 'websocket']|['tcp', 'kcp', 'websocket', 'quic']|g' $FRPC_PATH

	cd $PKG_PATH && echo "luci-app-frpc has been fixed!"
fi

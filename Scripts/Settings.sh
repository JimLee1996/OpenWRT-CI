#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh")
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
if [[ $WRT_TARGET == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
fi

#编译器优化
if [[ $WRT_TARGET != *"X86"* ]]; then
	echo "CONFIG_TARGET_OPTIONS=y" >> ./.config
	if [[ $WRT_CONFIG != 'K2P' ]]; then
		echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53\"" >> ./.config
	fi
fi

#网络设置
NET_SH="./package/base-files/files/etc/uci-defaults/991_set-network.sh"
if [ ! -f "$NET_SH" ]; then
	cat << 'EOF' > $NET_SH
#!/bin/sh

# 检查 network.globals.ula_prefix 是否存在且不为空
ula_prefix=$(uci get network.globals.ula_prefix 2>/dev/null)

if [ -n "$ula_prefix" ]; then
	uci set dhcp.wan6=dhcp
	uci set dhcp.wan6.interface='wan6'
	uci set dhcp.wan6.ignore='1'

	uci set dhcp.lan.force='1'
	uci set dhcp.lan.ra='hybrid'
	uci set dhcp.lan.ra_default='1'
	uci set dhcp.lan.max_preferred_lifetime='1800'
	uci set dhcp.lan.max_valid_lifetime='3600'

	uci del dhcp.lan.dhcpv6
	uci del dhcp.lan.ra_flags
	uci del dhcp.lan.ra_slaac
	uci add_list dhcp.lan.ra_flags='none'

	uci commit dhcp

	uci set network.wan6.reqaddress='try'
	uci set network.wan6.reqprefix='auto'
	uci set network.lan.ip6assign='64'
	uci set network.lan.ip6ifaceid='eui64'
	uci set network.globals.packet_steering='0'
	uci del network.globals.ula_prefix

	uci commit network
fi

exit 0
EOF
	chmod +x $NET_SH
fi

#系统Reload
RELOAD_SH="./package/base-files/files/etc/uci-defaults/999_auto-restart.sh"
if [ ! -f "$RELOAD_SH" ]; then
	cat << 'EOF' > $RELOAD_SH
#!/bin/sh

/etc/init.d/network restart
/etc/init.d/odhcpd restart
/etc/init.d/rpcd restart

exit 0
EOF
	chmod +x $RELOAD_SH
fi

#!/bin/bash
# INFO.sh defines package metadata for Synology build system.
# shellcheck disable=SC2034 # Variables consumed by pkg_dump_info.
source /pkgscripts/include/pkg_util.sh

package="PowerManagerNutEcoFlow"
version="0.1.0"
os_min_ver="7.0-40000"
displayname="Power Manager NUT EcoFlow"
description="Integrates Network UPS Tools with EcoFlow devices for power management."
arch="$(pkg_get_unified_platform)"
maintainer="Wild One Energy"
maintainer_url="https://github.com/wildone-energy/synology-power-manager-nut-ecoflow"
report_url="https://github.com/wildone-energy/synology-power-manager-nut-ecoflow/issues"
beta="no"
thirdparty="yes"
startable="yes"

pkg_dump_info

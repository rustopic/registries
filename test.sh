#!/bin/bash
# Rust Server Entry Script with Framework Support
# Server Files: /home/container

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║          ${WHITE}console.output.rust_server_entry_script${NC}                        ${CYAN}${BOLD}║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Make internal Docker IP address available to processes.
echo -e "${CYAN}${BOLD}[${WHITE}console.output.network${NC}]${NC} ${WHITE}console.output.configuring_internal_docker_ip${NC}"
export INTERNAL_IP=`ip route get 1 | awk '{print $(NF-2);exit}'`
if [ -n "${INTERNAL_IP}" ]; then
  echo -e "${GREEN}✓ ${WHITE}console.output.internal_ip_configured${NC}: ${WHITE}${BOLD}${INTERNAL_IP}${NC}"
else
  echo -e "${YELLOW}⚠️  ${WHITE}console.output.warning_could_not_determine_internal_ip${NC}"
fi
echo ""

## if auto_update is not set or to 1 update
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.update${NC}]${NC} ${WHITE}console.output.preparing_rust_server_update${NC}"
  
  # Branch sistemi: staging, aux01, aux02, aux03 için -beta parametresi eklenir
  # Branch null/boş ise normal public branch kullanılır
  STEAMCMD_UPDATE_CMD="+app_update 258550"
  
  if [ -n "${BRANCH}" ]; then
    case "${BRANCH}" in
      staging|aux01|aux02|aux03)
        STEAMCMD_UPDATE_CMD="${STEAMCMD_UPDATE_CMD} -beta ${BRANCH}"
        echo -e "${CYAN}ℹ️  ${WHITE}console.output.using_beta_branch${NC}: ${WHITE}${BOLD}${BRANCH}${NC}"
        ;;
      *)
        echo -e "${YELLOW}⚠️  ${WHITE}console.output.warning_unknown_branch${NC}: '${BRANCH}', ${WHITE}console.output.using_default_public_branch${NC}"
        ;;
    esac
  else
    echo -e "${BLUE}ℹ️  ${WHITE}console.output.using_default_public_branch${NC}"
  fi
  
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.update${NC}]${NC} ${WHITE}console.output.updating_rust_server_via_steamcmd${NC}"
  if ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous ${STEAMCMD_UPDATE_CMD} +quit; then
    echo -e "${GREEN}✓ ${WHITE}console.output.rust_server_updated_successfully${NC}"
  else
    echo -e "${RED}✗ ${WHITE}console.output.failed_to_update_rust_server${NC}"
    exit 1
  fi
  echo ""
else
  echo -e "${YELLOW}ℹ️  ${WHITE}console.output.auto_update_disabled_skipping_server_update${NC}"
  echo ""
fi

# Replace Startup Variables
echo -e "${CYAN}${BOLD}[${WHITE}console.output.startup${NC}]${NC} ${WHITE}console.output.processing_startup_variables${NC}"
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo -e "${CYAN}:/home/container$ ${WHITE}${MODIFIED_STARTUP}${NC}"
echo ""

# Framework kontrolü ve kurulumu
if [[ "${FRAMEWORK}" == "carbon" ]]; then
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.framework${NC}]${NC} ${WHITE}console.output.carbon_framework_detected${NC}"
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.carbon${NC}]${NC} ${WHITE}console.output.downloading_and_installing_carbon_framework${NC}"
  
  if curl -sSL "https://github.com/CarbonCommunity/Carbon.Core/releases/download/production_build/Carbon.Linux.Release.tar.gz" | tar zx; then
    echo -e "${GREEN}✓ ${WHITE}console.output.carbon_framework_installed_successfully${NC}"
    
    export DOORSTOP_ENABLED=1
    export DOORSTOP_TARGET_ASSEMBLY="$(pwd)/carbon/managed/Carbon.Preloader.dll"
    MODIFIED_STARTUP="LD_PRELOAD=$(pwd)/libdoorstop.so ${MODIFIED_STARTUP}"
    
    echo -e "${CYAN}ℹ️  ${WHITE}console.output.doorstop_enabled${NC}: ${WHITE}${DOORSTOP_ENABLED}${NC}"
    echo -e "${CYAN}ℹ️  ${WHITE}console.output.doorstop_target${NC}: ${WHITE}${DOORSTOP_TARGET_ASSEMBLY}${NC}"
  else
    echo -e "${RED}✗ ${WHITE}console.output.failed_to_install_carbon_framework${NC}"
    exit 1
  fi
  echo ""

elif [[ "$OXIDE" == "1" ]] || [[ "${FRAMEWORK}" == "oxide" ]]; then
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.framework${NC}]${NC} ${WHITE}console.output.oxide_framework_detected${NC}"
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.oxide${NC}]${NC} ${WHITE}console.output.downloading_and_installing_oxide_framework${NC}"
  
  if curl -sSL "https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip" > umod.zip; then
    if unzip -o -q umod.zip; then
      rm umod.zip
      echo -e "${GREEN}✓ ${WHITE}console.output.oxide_framework_installed_successfully${NC}"
    else
      echo -e "${RED}✗ ${WHITE}console.output.failed_to_extract_oxide_framework${NC}"
      rm -f umod.zip
      exit 1
    fi
  else
    echo -e "${RED}✗ ${WHITE}console.output.failed_to_download_oxide_framework${NC}"
    exit 1
  fi
  echo ""

else
  echo -e "${CYAN}${BOLD}[${WHITE}console.output.framework${NC}]${NC} ${WHITE}console.output.no_framework_specified_using_vanilla_rust_server${NC}"
  echo ""
fi

# Fix for Rust not starting
echo -e "${CYAN}${BOLD}[${WHITE}console.output.library${NC}]${NC} ${WHITE}console.output.configuring_library_paths${NC}"
export LD_LIBRARY_PATH=$(pwd)/RustDedicated_Data/Plugins/x86_64:$(pwd)
echo -e "${GREEN}✓ ${WHITE}console.output.ld_library_path_configured${NC}: ${WHITE}${LD_LIBRARY_PATH}${NC}"
echo ""

# Run the Server
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     ✓ ${WHITE}console.output.rust_server_starting${NC}     ${GREEN}${BOLD}║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

node /wrapper.js "${MODIFIED_STARTUP}"

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
echo -e "${CYAN}${BOLD}║          Rust Server Entry Script                        ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Make internal Docker IP address available to processes.
echo -e "${CYAN}${BOLD}[Network]${NC} ${WHITE}Configuring internal Docker IP address...${NC}"
export INTERNAL_IP=`ip route get 1 | awk '{print $(NF-2);exit}'`
if [ -n "${INTERNAL_IP}" ]; then
  echo -e "${GREEN}✓ Internal IP configured: ${WHITE}${BOLD}${INTERNAL_IP}${NC}"
else
  echo -e "${YELLOW}⚠️  Warning: Could not determine internal IP${NC}"
fi
echo ""

## if auto_update is not set or to 1 update
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
  echo -e "${CYAN}${BOLD}[Update]${NC} ${WHITE}Preparing Rust server update...${NC}"
  
  # Branch sistemi: staging, aux01, aux02, aux03 için -beta parametresi eklenir
  # Branch null/boş ise normal public branch kullanılır
  STEAMCMD_UPDATE_CMD="+app_update 258550"
  
  if [ -n "${BRANCH}" ]; then
    case "${BRANCH}" in
      staging|aux01|aux02|aux03)
        STEAMCMD_UPDATE_CMD="${STEAMCMD_UPDATE_CMD} -beta ${BRANCH}"
        echo -e "${CYAN}ℹ️  Using beta branch: ${WHITE}${BOLD}${BRANCH}${NC}"
        ;;
      *)
        echo -e "${YELLOW}⚠️  Warning: Unknown branch '${BRANCH}', using default public branch${NC}"
        ;;
    esac
  else
    echo -e "${BLUE}ℹ️  Using default public branch${NC}"
  fi
  
  echo -e "${CYAN}${BOLD}[Update]${NC} ${WHITE}Updating Rust server via SteamCMD...${NC}"
  if ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous ${STEAMCMD_UPDATE_CMD} +quit; then
    echo -e "${GREEN}✓ Rust server updated successfully${NC}"
  else
    echo -e "${RED}✗ Failed to update Rust server${NC}"
    exit 1
  fi
  echo ""
else
  echo -e "${YELLOW}ℹ️  Auto-update disabled (AUTO_UPDATE=0), skipping server update${NC}"
  echo ""
fi

# Replace Startup Variables
echo -e "${CYAN}${BOLD}[Startup]${NC} ${WHITE}Processing startup variables...${NC}"
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo -e "${CYAN}:/home/container$ ${WHITE}${MODIFIED_STARTUP}${NC}"
echo ""

# Framework kontrolü ve kurulumu
if [[ "${FRAMEWORK}" == "carbon" ]]; then
  echo -e "${CYAN}${BOLD}[Framework]${NC} ${WHITE}Carbon framework detected${NC}"
  echo -e "${CYAN}${BOLD}[Carbon]${NC} ${WHITE}Downloading and installing Carbon framework...${NC}"
  
  if curl -sSL "https://github.com/CarbonCommunity/Carbon.Core/releases/download/production_build/Carbon.Linux.Release.tar.gz" | tar zx; then
    echo -e "${GREEN}✓ Carbon framework installed successfully${NC}"
    
    export DOORSTOP_ENABLED=1
    export DOORSTOP_TARGET_ASSEMBLY="$(pwd)/carbon/managed/Carbon.Preloader.dll"
    MODIFIED_STARTUP="LD_PRELOAD=$(pwd)/libdoorstop.so ${MODIFIED_STARTUP}"
    
    echo -e "${CYAN}ℹ️  DOORSTOP enabled: ${WHITE}${DOORSTOP_ENABLED}${NC}"
    echo -e "${CYAN}ℹ️  DOORSTOP target: ${WHITE}${DOORSTOP_TARGET_ASSEMBLY}${NC}"
  else
    echo -e "${RED}✗ Failed to install Carbon framework${NC}"
    exit 1
  fi
  echo ""

elif [[ "$OXIDE" == "1" ]] || [[ "${FRAMEWORK}" == "oxide" ]]; then
  echo -e "${CYAN}${BOLD}[Framework]${NC} ${WHITE}Oxide framework detected${NC}"
  echo -e "${CYAN}${BOLD}[Oxide]${NC} ${WHITE}Downloading and installing Oxide framework...${NC}"
  
  if curl -sSL "https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip" > umod.zip; then
    if unzip -o -q umod.zip; then
      rm umod.zip
      echo -e "${GREEN}✓ Oxide framework installed successfully${NC}"
    else
      echo -e "${RED}✗ Failed to extract Oxide framework${NC}"
      rm -f umod.zip
      exit 1
    fi
  else
    echo -e "${RED}✗ Failed to download Oxide framework${NC}"
    exit 1
  fi
  echo ""

else
  echo -e "${CYAN}${BOLD}[Framework]${NC} ${WHITE}No framework specified, using vanilla Rust server${NC}"
  echo ""
fi

# Fix for Rust not starting
echo -e "${CYAN}${BOLD}[Library]${NC} ${WHITE}Configuring library paths...${NC}"
export LD_LIBRARY_PATH=$(pwd)/RustDedicated_Data/Plugins/x86_64:$(pwd)
echo -e "${GREEN}✓ LD_LIBRARY_PATH configured: ${WHITE}${LD_LIBRARY_PATH}${NC}"
echo ""

# Run the Server
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     ✓ Rust Server Starting...                            ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

node /wrapper.js "${MODIFIED_STARTUP}"

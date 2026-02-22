#!/usr/bin/env bash
if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run script with sudo"
  exit 1
fi


################################################
# Add to list of MacOS brew cask apps to install
################################################
mac_brew_cask_apps=(
  iterm2
  warp
  brave-browser
  slack
  notion
  )

install_linux_tools()
{
  # echo "Linux install..."
  echo "⏭️  No tools for Linux..."
  return 0
}

install_macos_tools()
{
    echo "🍎 MacOS install..."
    arch=$(sysctl -n machdep.cpu.brand_string)
    if [[ "$arch" == *"Apple"* ]]; then
      echo "✅ This Mac is using Apple Silicon."
    else
      echo "✅ This Mac is using an Intel processor."
    fi

	  # Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
    # as Brew uses different paths for Apple Silicon and Intel Macs
    # See https://docs.brew.sh/Installation#unattended-installation

    eval "$($(which brew) shellenv)"

    brew update

    for app in "${mac_brew_cask_apps[@]}"; do
      brew install --cask "$app"
    done

}

install_common()
{
 return 0
}
install_common


if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  install_linux_tools
elif [[ "$OSTYPE" == "darwin"* ]]; then
  install_macos_tools
fi

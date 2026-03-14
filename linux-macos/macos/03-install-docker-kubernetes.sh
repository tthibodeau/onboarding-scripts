#!/usr/bin/env bash
echo "📥 MacOS install..."

install_docker_desktop_macos() {
	echo "Installing Docker..."

	CPU_ARCHITECTURE=$(uname -m)
	if [[ "$CPU_ARCHITECTURE" != "arm64" ]]; then
		CPU_ARCHITECTURE="amd64"
	fi

	curl https://desktop.docker.com/mac/main/$CPU_ARCHITECTURE/Docker.dmg --output docker-desktop-4.11.0-$CPU_ARCHITECTURE.dmg

	sudo hdiutil attach docker-desktop-4.11.0-$CPU_ARCHITECTURE.dmg
	sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
	sudo hdiutil detach /Volumes/Docker
}

install_docker_desktop_macos

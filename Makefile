MAKEFLAGS='--debug=basic'

GAME=AventureKids
ITCH_GAME_NAME=lincroyable-aventure


ITCH_USER_NAME=hephep
GODOT=../../tools/Godot/Godot_v4.7.1-stable_linux.x86_64
BUTLER := tools/butler/butler

BUILD_TIME := $(shell date "+%F-%T")
GIT_HASH := $(shell git rev-parse --short HEAD)
PREVIOUS_HASH = $(shell tail deploy/itch-web -n2 | head -n1 | cut -d' ' -f4)
GIT_UNCOMMITED_FILE_COUNT := $(shell git status --porcelain 2>/dev/null | wc -l)

FILES := $(shell find . -name "*.gd" -o -name "*.tscn" -o -name "*.tres" -o -name "*.res" -not -path ".godot")


build/linux/${GAME}_linux.x86_64: ${FILES}
	mkdir -p build/linux ; \
	${GODOT} --path . --headless --export-release "linux" build/linux/${GAME}_linux.x86_64

build/linux/linux.zip: build/linux/${GAME}_linux.x86_64
	rm -f ${@}
	zip -r -j ${@} build/linux/.

deploy/itch-linux: build/linux/linux.zip tools/butler/butler deploy/changelog
	$(BUTLER) upgrade
	$(BUTLER) push build/linux/linux.zip $(ITCH_USER_NAME)/$(ITCH_GAME_NAME):linux && \
	echo "${BUILD_TIME} from ${GIT_HASH} (dirty_files:${GIT_UNCOMMITED_FILE_COUNT})" >> deploy/itch-linux ; \
	git log  "$(shell tail deploy/itch-linux -n1 | cut -d' ' -f3)..HEAD" >> "deploy/changelog/itch_linux-${BUILD_TIME}"


build/windows/${GAME}_windows.exe: ${FILES}
	mkdir -p build/windows ; \
	${GODOT} --path . --headless --export-release "windows" build/windows/${GAME}_windows.exe

build/windows/windows.zip: build/windows/${GAME}_windows.exe
	rm -f ${@}
	zip -r -j ${@} build/windows/.

deploy/itch-windows: build/windows/windows.zip tools/butler/butler deploy/changelog
	$(BUTLER) upgrade
	$(BUTLER) push build/windows/windows.zip $(ITCH_USER_NAME)/$(ITCH_GAME_NAME):windows && \
	echo "${BUILD_TIME} from ${GIT_HASH} (dirty_files:${GIT_UNCOMMITED_FILE_COUNT})" >> deploy/itch-windows ; \
	git log  "$(shell tail deploy/itch-windows -n1 | cut -d' ' -f3)..HEAD" >> "deploy/changelog/itch_windows-${BUILD_TIME}"

build/web/index.html: ${FILES}
	mkdir -p build/web ; \
	${GODOT} --path . --headless --export-release "web" build/web/index.html

build/web/web.zip: build/web/index.html
	rm -f ${@}
	zip -r ${@} build/web/.

deploy/itch-web: build/web/web.zip tools/butler/butler deploy/changelog
	$(BUTLER) upgrade
	$(BUTLER) push build/web/web.zip $(ITCH_USER_NAME)/$(ITCH_GAME_NAME):html5 && \
	echo "${BUILD_TIME} from ${GIT_HASH} (dirty_files:${GIT_UNCOMMITED_FILE_COUNT})" >> deploy/itch-web ; \
	git log  "$(shell tail deploy/itch-web -n1 | cut -d' ' -f3)..HEAD" >> "deploy/changelog/itch_web-${BUILD_TIME}"


deploy-web: deploy/itch-web

deploy-itch: deploy/itch-web deploy/itch-linux deploy/itch-windows

.PHONY: clean
clean:
	rm -f -r build/linux
	rm -f -r build/web
	rm -f -r build/windows

deploy/changelog:
	mkdir -p ${@}

tools/butler/butler:
	curl -L -o /tmp/butler.zip https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
	mkdir -p tools/butler
	cd tools/butler && unzip /tmp/butler.zip
	chmod +x tools/butler/butler
